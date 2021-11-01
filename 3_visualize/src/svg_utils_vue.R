gwl_to_peak <- function(file_out, gw_anomaly_data_w_colors){
  # Create timeseries data to draw peak animation with D3
  gw_anomaly_data_w_colors %>% 
    mutate(quant = str_replace(quant_category, " ", ""),
           path_y = round(50-daily_quant, digits = 0)) %>%
    #filter(!is.na(quant)) %>%
    mutate(site_no = paste0('gwl_', site_no)) %>%
    select(site_no, day_seq, daily_quant, path_y) %>%
    dcast(day_seq~site_no, value.var = 'path_y') %>%
    arrange(day_seq) %>%
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

  ## write timeseries % of sites in each category 
  gw_anomaly_data_w_colors %>% 
    filter(!is.na(quant_category)) %>% # filtering out dates with no category 
    group_by(Date, day_seq, quant_category) %>%
    summarize(n_sites = length(unique(site_no))) %>% 
    # join with the total number of sites WITH DATA for each day
    left_join(gw_anomaly_data_w_colors  %>%  
                filter(!is.na(quant_category))%>% 
                group_by(Date, day_seq) %>%
                summarize(n_sites_total = length(unique(site_no)))) %>%
    mutate(perc = n_sites/n_sites_total) %>%
    ungroup() %>%
    mutate(cat = gsub(" ", "", quant_category),
           perc = round(perc, 3)) %>%
    select(-quant_category) %>%
    reshape2::dcast(Date+day_seq+n_sites_total~cat, value.var = "perc") %>%
    arrange(day_seq) %>%
    write_csv(file_out)
  
}


