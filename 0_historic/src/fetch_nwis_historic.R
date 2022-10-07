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

fetch_gw_site_tz <- function(sites) {
  readNWISsite(sites) %>% 
    select(site_no, tz_cd)
}

fetch_gw_site_info <- function(data_fn) {
  sites <- read_csv(data_fn, col_types = 'cDn') %>% 
    pull(site_no) %>% 
    unique()
  readNWISsite(sites) %>% 
    select(site_no, station_nm, state_cd, dec_lat_va, dec_long_va, tz_cd)
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

convert_uv_to_dv <- function(target_name, gw_uv_data_fn, site_tz_xwalk) {
  read_feather(gw_uv_data_fn) %>% 
    
    ### Convert to date using local timezone
    
    # Remove the tz_cd column that is downloaded with the data
    select(-tz_cd) %>% 
    # Join in the local timezone information for each site
    left_join(site_tz_xwalk, by = "site_no") %>% 
    # Change the dateTime column to just the date. Need to use the timezone
    # rather than UTC so that days are treated appropriately. Seems overly 
    # complicated but you can't use `format()` with more than one tz, so 
    # this vectorizes that call per timezone. Not using rowwise() because 
    # that would be slow. Doing a single call per timezone speeds this up.
    group_by(tz_cd) %>% 
    nest() %>% 
    pmap(function(tz_cd, data) {
      data %>% mutate(Date = POSIXct_to_Date_tz(dateTime, tz_cd))
    }) %>% 
    bind_rows() %>% 
    
    ### Reduce each instantaneous value to a single average for each date
    group_by(site_no, Date) %>% 
    summarize(GWL = mean(GWL_inst, na.rm = TRUE), .groups = "keep") %>% 
    write_feather(target_name)
}

# Convert POSIXct to Dates for a given timezone
# Only works with one tz_abbr at a time
POSIXct_to_Date_tz <- function(posix_dates, tz_abbr) {
  # The "AST" for "Atlantic Standard Time" is not recognized by `format()`
  # According to https://www.r-bloggers.com/2018/07/a-tour-of-timezones-troubles-in-r/
  # we should be using location-based timezones to properly handle daylight savings time
  # Not going to worry about the Indiana and Phoenix nuances for now.
  tz_abbr_adj <- switch(
    tz_abbr,
    "AST" = "America/Virgin", 
    "EST" = "America/New_York",
    "EDT" = "America/New_York",
    "CST" = "America/Chicago", 
    "CDT" = "America/Chicago",
    "MST" = "America/Denver",
    "MDT" = "America/Denver",
    "PST" = "America/Los_Angeles",
    "PDT" = "America/Los_Angeles",
    "AKST" = "America/Juneau",
    "AKDT" = "America/Juneau",
    "HST" = "US/Hawaii",
    "HDT" = "US/Hawaii",
    tz_abbr)
  
  # Needs to retain POSIXct class and timestamp for extracting tz with '%Z' next
  format(posix_dates, "%Y-%m-%d %H:%M:%S", tz=tz_abbr_adj, usetz=TRUE) %>% 
    as.POSIXct(tz=tz_abbr_adj) %>% 
    # For some reason, timezones above will only return daylight time,
    # though it might have to due with whether your computer is in
    # daylight or standard time at the moment you run the conversion
    # code. I believe that the function below will appropriately account
    # for that because it will test ST vs DT and do the appropriate switch.
    adjust_for_daylight_savings(tz_desired = tz_abbr) %>% 
    # Drop times and timezone before converting to a plain date or it will
    # adjust using your local timezone.
    format('%Y-%m-%d') %>% as.Date()
  
}

# Note that the output from this fxn will say 'PDT' but mean 'PST'
# because you can't have a timezone of 'PST' (it will convert to GMT, 
# even when using `lubridate::force_tz(., 'PST')`). This is used
# internally before dropping time and going to a day, so I am 
# accepting the risk.
adjust_for_daylight_savings <- function(posix_dates, tz_desired) {
  
  # To go from daylight time (DT) to standard time
  #  (ST), subtract an hour and vice versa. If the
  #  `from` and `to` values are the same, don't 
  #  change anything about the dates.
  tz_conversion_xwalk <- tibble(
    from = c('DT', 'ST', 'ST', 'DT'),
    to = c('ST', 'DT', 'ST', 'DT'),
    conversion_sec = c(-3600, 3600, 0, 0)
  )
  
  # There could be more than one timezone if the date range spans across
  # the standard to daylight savings switch. Thus, we should be able to 
  # convert each date independently (which happens in this piped sequence)
  tibble(
    in_dates = posix_dates,
    in_tz = format(posix_dates, "%Z")
  ) %>% 
    mutate(
      # Use the last two characters in both the current and desired
      # timezones for matching with the conversion xwalk
      from = stringr::str_sub(in_tz, -2, -1),
      to = stringr::str_sub(tz_desired, -2, -1)
    ) %>% 
    # Join in conversion xwalk
    left_join(tz_conversion_xwalk, by = c("from", "to")) %>%
    # Alter the date values to match the desired timezone.
    mutate(out_dates = in_dates + conversion_sec) %>% 
    # Pull out just the dates to return
    pull(out_dates)
  
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
