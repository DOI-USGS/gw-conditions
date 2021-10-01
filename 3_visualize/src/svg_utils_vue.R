gwl_to_peak <- function(file_out, gw_anomaly_data_w_colors){
  # Create timeseries data to draw peak animation with D3
  gw_anomaly_data_w_colors %>%
    mutate(quant = str_replace(quant_category, " ", ""),
           path_y = round(50-daily_quant, digits = 0)) %>%
    filter(!is.na(quant)) %>%
    mutate(site_no = paste0('gwl_', site_no)) %>%
    select(site_no, wyday, daily_quant, path_y) %>%
    dcast(wyday~site_no, value.var = 'path_y') %>%
    arrange(wyday) %>%
    write_csv(file_out)
}

get_site_coords <- function(file_out, sites_sf){
  # Get site positioning to draw sites with d3
  convert_coords_to_svg(sites_sf, svg_width = 1000, view_bbox = st_bbox(generate_usa_map_data()))%>% 
    mutate(site_no = paste0('gwl_', sites_sf$site_no)) %>% 
    filter(!is.na(x)) %>%
    write_csv(file_out)
}

site_prop_timeseries <- function(file_out, gw_anomaly_data_w_colors){
  gw <- gw_anomaly_data_w_colors %>% 
    filter(!is.na(quant_category)) %>% 
    group_by(Date) %>%
    filter(wyday == max(wyday))
  
  ## write json with timeseries of sites in each category 
  gw %>% 
    group_by(Date, wyday, quant_category) %>%
    summarize(n_sites = length(unique(site_no))) %>% 
    left_join(gw  %>% 
                group_by(Date, wyday) %>%
                summarize(n_sites_total = length(unique(site_no)))) %>%
    mutate(perc = n_sites/n_sites_total) %>%
    ungroup() %>%
    mutate(cat = gsub(" ", "", quant_category),
           perc = round(perc, 3)) %>%
    select(-quant_category) %>%
    reshape2::dcast(Date+wyday+n_sites_total~cat, value.var = "perc") %>%
    arrange(wyday) %>%
    write_csv(file_out)
  
}