filter_historic_fetched_data <- function(target_name, historic_gw_data_fn, min_years, allowed_site_types) {
  
  historic_gw_data <- read_csv(historic_gw_data_fn, col_types = 'cDn') 
  
  sites_meet_min_yrs <- historic_gw_data %>%  
    group_by(site_no) %>% 
    summarize(n_days = n()) %>% 
    # Check that the number of days of data is at least 3 full years worth
    filter(n_days >= 365*min_years) %>% 
    pull(site_no)
  
  # 6/4/2021: One of the sites had its leading zero dropped along the way. I  
  # know that it is a LK site, which we are not keeping, so going to manually 
  # filter it out for now and return to this the next time we go to rebuild.
  site_nums <- unique(historic_gw_data$site_no)
  i_bad <- which(site_nums %in% c("5346050")) # It should be "05346050"
  sites_meet_site_tp <- readNWISsite(site_nums[-i_bad]) %>% 
    select(site_no, site_tp_cd) %>% 
    filter(site_tp_cd %in% allowed_site_types) %>% 
    pull(site_no)
  
  # Actually restrict the data based on these criteria
  historic_gw_data %>% 
    filter(site_no %in% sites_meet_min_yrs) %>% 
    filter(site_no %in% sites_meet_site_tp) %>%
    write_csv(target_name) 
}
