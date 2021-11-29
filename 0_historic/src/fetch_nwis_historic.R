#' Fetch all NWIS sites that have groundwater level data during the appropriate time period
fetch_gw_historic_sites <- function(start_date, end_date, bounding_box, param_cd){
  
  hucs <- zeroPad(1:21, 2) # all hucs
  
  sites <- tibble()
  for(huc in hucs){
    message(sprintf("Trying HUC %s ...", huc))
    sites <- tryCatch(
      whatNWISdata(huc = huc, 
                   startDate = start_date,
                   endDate = end_date,
                   parameterCd = param_cd) %>% 
        apply_selection_criteria() %>% 
        unique(), 
      error = function(e) return()
    ) %>% bind_rows(sites)
  }
    
  return(sites)
}

apply_selection_criteria <- function(df) {
  # Choose either dv or uv to pull
  # Keep oldest record either UV or DV+00003, then choose DV if tie
  df %>% 
    filter(data_type_cd %in% c("uv", "dv"),
           is.na(stat_cd) | stat_cd == "00003") %>% 
    group_by(site_no) %>% 
    # Account for the fact that inst data will have reported data for today's data but "daily" data will not 
    # yet since the day has to complete first, so having one day of data more than dv shouldn't cause us to 
    # choose instantaneous instead. The same is true if there were partial days on the front end (I noticed
    # quite a few instances where "uv" started one day before "dv" and I imagine this is because the day was
    # only partially recorded, so they didn't want to include a daily value. This appears to happen more
    # often then them starting on the same day, so I may miss a few that don't do this but willing to take
    # the risk.)
    mutate(begin_date_fix = ifelse(data_type_cd == "uv", 1, 0), # can't return dates from ifelse
           begin_date = begin_date + begin_date_fix,
           end_date_fix = ifelse(data_type_cd == "uv", 1, 0), # can't return dates from ifelse
           end_date = end_date - end_date_fix) %>%
    # Handle ties, by sorting so "dv" is first because `which.max` will return the first one if there is a tie
    arrange(site_no, data_type_cd) %>% # "dv" comes before "uv" alphabetically
    mutate(to_keep = which.max(end_date - begin_date),
           keep_row = row_number() == to_keep) %>% 
    ungroup() %>% 
    filter(keep_row) %>% 
    select(site_no, data_type_cd)
}

pull_sites_by_service <- function(site_df, service) {
  site_df %>% filter(data_type_cd == service) %>% pull(site_no)
}

fetch_gw_site_info <- function(data_fn) {
  sites <- read_csv(data_fn, col_types = 'cDn') %>% 
    pull(site_no) %>% 
    unique()
  readNWISsite(sites) %>% 
    select(site_no, station_nm, state_cd, dec_lat_va, dec_long_va)
}

fetch_addl_uv_sites <- function(addl_states, param_cd, start_date, end_date) {
  site_nums <- c()
  for(i in 1:length(addl_states)) {
    site_nums_i <- whatNWISdata(
      stateCd = addl_states[i], parameterCd = param_cd, service = 'uv',
      startDate = start_date, endDate = end_date) %>% 
      pull(site_no) %>% unique()
    site_nums <- c(site_nums, site_nums_i)
  }
  return(site_nums)
}

fetch_gw_historic_dv <- function(target_name, gw_sites, start_date, end_date, param_cd) {
  readNWISdv(
    siteNumbers = gw_sites,
    startDate = start_date,
    endDate = end_date,
    parameterCd = param_cd,
    statCd = "00003") %>%
    rename(GWL := sprintf("X_%s_00003", param_cd)) %>% 
    select(site_no, Date, GWL) %>% 
    write_feather(target_name)
}

fetch_gw_historic_uv <- function(target_name, gw_sites, start_date, end_date, param_cd) {
  readNWISuv(
    siteNumbers = gw_sites,
    startDate = start_date,
    endDate = end_date,
    parameterCd = param_cd) %>%
    rename(GWL_inst := sprintf("X_%s_00000", param_cd)) %>% 
    write_feather(target_name)
}

convert_uv_to_dv <- function(target_name, gw_uv_data_fn) {
  read_feather(gw_uv_data_fn) %>% 
    mutate(Date = as.Date(dateTime)) %>% 
    group_by(site_no, Date) %>% 
    summarize(GWL = mean(GWL_inst, na.rm = TRUE), .groups = "keep") %>% 
    write_feather(target_name)
}

combine_gw_fetches <- function(target_name, dv_fn, uv_fn, uv_addl_fn) {
  read_csv(dv_fn, col_types = 'cDn') %>% 
    bind_rows(read_csv(uv_fn, col_types = 'cDn')) %>% 
    bind_rows(read_csv(uv_addl_fn, col_types = 'cDn')) %>% 
    write_csv(target_name)
}

combine_gw_sites <- function(gw_site_df, uv_addl_sites, param_cd, addl_param_cd, addl_states) {
  # First find out what state the additional sites are in
  # Then you can figure out what parameter code they should have
  addl_sites_df <- readNWISsite(uv_addl_sites) %>%
    mutate(state_abbr = stateCdLookup(state_cd)) %>% 
    left_join(tibble(state_abbr = addl_states, 
                     param_cd = addl_param_cd)) %>% 
    mutate(data_type_cd = "uv") %>% 
    select(site_no, data_type_cd, param_cd)
  
  mutate(gw_site_df, param_cd = param_cd) %>% 
    bind_rows(addl_sites_df)
}
