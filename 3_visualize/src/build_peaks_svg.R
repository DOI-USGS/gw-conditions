
build_peaks_svg <- function(out_file, data_in, sites_sf, svg_width, svg_height) {
  
  svg_root <- init_svg(viewbox_dims = c(0, 0, svg_width=svg_width, svg_height=svg_height))
  
  add_background_map(svg_root, svg_width = svg_width, outline_states = FALSE)
  
  # Add spark line within group per site
  
  # TODO: THIS ONLY WORKS FOR A SINGLE DAY RIGHT NOW. I CHOSE OCT 31, 2019
  # TODO: Blanket removing any path with an NA in it. There is a smarter way 
  # to do this but will come back to that.
  data_in <- data_in %>% 
    filter(Date == as.Date("2019-10-31")) %>% 
    filter(!grepl("NA", path))
  
  sites <- unique(data_in$site_no)
  for(s in sites) {
    site_coords_svg <- sites_sf %>%
      filter(site_no == s) %>%
      convert_coords_to_svg(svg_width = svg_width, view_bbox = st_bbox(generate_usa_map_data()))
    
    gw_data_s <- data_in %>% filter(site_no == s)
    
    # Spark lines centered at GW location
    svg_root %>%
      add_grp(grp_nm = s, trans_x = site_coords_svg$x,
              trans_y = site_coords_svg$y) %>%
      xml_add_child("path",
                    class = sprintf('gwl_%s', s),
                    style = sprintf("stroke: none; fill: %s; fill-opacity: 50%%", gw_data_s$color),
                    d = gw_data_s$path)
    
  }
  
  xml2::write_xml(svg_root, file = out_file)
}
send_to_vue <- function(out_file, in_file){
  # Copy current time period to vue
  file.copy(in_file, 
            out_file,  
            overwrite = TRUE)
  
}
list_svg_files <- function(out_file, svg_fp = "src/assets"){
  tibble(fp = list.files(svg_fp, pattern = ".svg")) %>%
    mutate(date_start = as.Date(word(fp, 3, 3, sep="_"), format = "%Y%m%d"),
           date_end = as.Date(word(str_replace(fp, ".svg", ""), 4, 4, sep="_"), format = "%Y%m%d")) %>%
    write_csv(out_file)
  
  # Copy to vue
  file.copy(out_file, 
            sprintf("public/svg_files.csv"), 
            overwrite = TRUE)
}
