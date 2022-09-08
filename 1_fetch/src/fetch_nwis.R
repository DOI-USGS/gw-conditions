
pull_sites_by_query <- function(site_df, service, param) {
  site_df %>% 
    filter(data_type_cd == service) %>%
    filter(param_cd == param) %>% 
    pull(site_no)
}

fetch_gw_dv <- function(target_name, gw_sites, start_date, end_date, param_cd) {
  readNWISdv(
    siteNumbers = gw_sites,
    startDate = start_date,
    endDate = end_date,
    parameterCd = param_cd,
    statCd = "00003") %>%
    rename(GWL := sprintf("X_%s_00003", param_cd)) %>% 
    select(site_no, Date, GWL) %>% 
    distinct() %>% # need this to avoid some duplicates
    write_feather(target_name)
}

fetch_gw_uv <- function(target_name, gw_sites, start_date, end_date, param_cd) {
  readNWISuv(
    siteNumbers = gw_sites,
    startDate = start_date,
    endDate = end_date,
    parameterCd = param_cd) %>%
    rename(GWL_inst := sprintf("X_%s_00000", param_cd)) %>% 
    distinct() %>% # need this to avoid some duplicates
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
    summarize(GWL = mean(GWL_inst, na.rm = TRUE)) %>% 
    write_feather(target_name)
}

# Convert POSIXct to Dates for a given timezone
# Only works with one tz_abbr at a time
POSIXct_to_Date_tz <- function(posix_dates, tz_abbr) {
  # The "AST" for "Atlantic Standard Time" is not recognized by `format()`
  # According to https://www.r-bloggers.com/2018/07/a-tour-of-timezones-troubles-in-r/
  # we should be using location-based timezones to properly handle daylight savings time
  # Not going to worry about the Indiana and Phoenix nuances for now.
  tz_abbr <- switch(
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
  as.Date(format(posix_dates, "%Y-%m-%d", tz=tz_abbr, usetz=TRUE))
}

combine_gw_fetches <- function(target_name, dv_fn, uv_fn, uv_addl_fn) {
  read_csv(dv_fn, col_types = 'cDn') %>% 
    bind_rows(read_csv(uv_fn, col_types = 'cDn')) %>% 
    bind_rows(read_csv(uv_addl_fn, col_types = 'cDn')) %>% 
    write_csv(target_name)
}
