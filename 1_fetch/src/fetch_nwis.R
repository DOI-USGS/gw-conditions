#' Fetch all NWIS sites that have groundwater level data during the appropriate time period
fetch_gw_site_info <- function(filename, start_date, end_date, param_cd){
  
  hucs <- zeroPad(1:21, 2) # all hucs
  
  site_info <- data.frame()
  for(huc in hucs){
    message(sprintf("Trying HUC %s ...", huc))
    site_info <- tryCatch(
      whatNWISdata(huc = huc, 
                   service = "dv", 
                   startDate = start_date,
                   endDate = end_date,
                   parameterCd = param_cd,
                   statCd = "00003") %>%
        select(site_no, station_nm, dec_lat_va, dec_long_va) %>%
        unique(), 
      error = function(e) return(data.frame())
    ) %>% rbind(site_info)
  }
  
  saveRDS(site_info, filename)
}

fetch_gw_data <- function(filename, sites, start_date, end_date, param_cd, request_limit = 10) {
  
  # Number indicating how many sites to include per dataRetrieval request to prevent
  # errors from requesting too much at once. More relevant for surface water requests.
  req_bks <- seq(1, length(sites), by=request_limit)
  
  gwl_data <- data.frame()
  
  # Need a for loop and not `purrr::map` or `lapply` so that we don't overwhelm NWIS services
  for(i in req_bks) {
    last_site <- min(i+request_limit-1, length(sites))
    get_sites <- sites[i:last_site]
    
    data_i <- tryCatch(
      readNWISdv(
        siteNumbers = get_sites,
        startDate = start_date,
        endDate = end_date,
        parameterCd = param_cd,
        statCd = "00003") %>%
      renameNWISColumns() %>% 
      # WLBLS = "Water level below surface"
      select(site_no, Date, GWL = WLBLS), 
      # no data returned situation
      error = function(e) return()
    )
    
    gwl_data <- rbind(gwl_data, data_i)
    message(sprintf("Completed pulling gwl data for %s of %s sites", last_site, length(sites)))
  }
  
  gwl_data_unique <- dplyr::distinct(gwl_data) # need this to avoid some duplicates
  
  saveRDS(gwl_data_unique, filename)
  
}
