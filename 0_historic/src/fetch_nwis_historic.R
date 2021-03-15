#' Fetch all NWIS sites that have groundwater level data during the appropriate time period
fetch_gw_historic_sites <- function(start_date, end_date, bounding_box, param_cd){
  
  hucs <- zeroPad(1:21, 2) # all hucs
  
  sites <- c()
  for(huc in hucs){
    message(sprintf("Trying HUC %s ...", huc))
    sites <- tryCatch(
      whatNWISdata(huc = huc, 
                   service = "dv", 
                   startDate = start_date,
                   endDate = end_date,
                   parameterCd = param_cd,
                   statCd = "00003") %>%
        pull(site_no) %>%
        unique(), 
      error = function(e) return()
    ) %>% c(sites)
  }
  
  return(sites)
}

fetch_gw_site_info <- function(sites) {
  readNWISsite(sites) %>% 
    select(site_no, station_nm, state_cd, dec_lat_va, dec_long_va)
}

fetch_gw_historic <- function(target_name, gw_sites, start_date, end_date, param_cd, stat_cd) {
  readNWISdv(
    siteNumbers = gw_sites,
    startDate = start_date,
    endDate = end_date,
    parameterCd = param_cd,
    statCd = stat_cd) %>%
    rename(GWL := sprintf("X_%s_%s", param_cd, stat_cd)) %>% 
    select(site_no, Date, GWL) %>% 
    write_feather(target_name)
}
