
create_gif <- function(gif_filename, png_file_yml, frame_delay) {
  # Build gif from pngs with magick and simplify with gifsicle
  
  if(!dir.exists("4_animate/tmp")) dir.create("4_animate/tmp")
  
  png_frames <- names(yaml::yaml.load_file(png_file_yml))
  png_dir <- unique(dirname(png_frames))
  
  # Rename frames numerically to make sure they are used in order
  file_name_df <- tibble(origName = png_frames,
                         countFormatted = zeroPad(1:length(png_frames), padTo = 3),
                         newName = sprintf("%s/frame_%s.png", png_dir, countFormatted))
  file.rename(from = file_name_df$origName, to = file_name_df$newName)
  png_frames_str <- paste(file_name_df$newName, collapse = " ")
  
  tmp_dir <- '4_animate/tmp/magick'
  if(!dir.exists(tmp_dir)) dir.create(tmp_dir)
  
  # Create gif using magick
  pre_downscale_fn <- sprintf("4_animate/tmp/pre_downscale_%s", basename(gif_filename))
  # magick_command <- sprintf(
  #   "convert -define registry:temporary-path='%s' -loop 0 -delay 20 %s %s",
  #   tmp_dir, png_frames_str, pre_downscale_fn)
  # Got ImageMagick gif advice from: http://mariovalle.name/postprocessing/ImageTools.html#basic
  magick_command <- sprintf(
    "convert -delay %s -dispose None +page %s -loop 0 %s",
    frame_delay, png_frames_str, pre_downscale_fn)
  
  if(Sys.info()[['sysname']] == "Windows") {
    magick_command <- sprintf('magick %s', magick_command)
  }
  
  system(magick_command)
  
  # simplify the gif with gifsicle - cuts size by about 2/3
  system(sprintf('gifsicle -i %s -O3 --colors 256 -o %s',
                 pre_downscale_fn, gif_filename))
  
  # Reset file names
  file.rename(from = file_name_df$newName, to = file_name_df$origName)
}
