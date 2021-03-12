# s3_get will only download and save the file exactly in the filepath it appears on S3
# So, this function uses S3_get but then moves the file where we want it
fetch_s3 <- function(target_name, s3_file) {
  local_file <- s3_get(s3_file) 
  file.copy(local_file, target_name, overwrite = TRUE)
  file.remove(local_file)
  
  # Clean up and remove the dir if there are no files
  if(length(list.files("gw-conditions")) == 0) unlink(dirname(local_file), recursive = TRUE)
  
}
