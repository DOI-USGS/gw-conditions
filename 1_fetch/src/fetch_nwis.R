#' Fetch NWIS sites within the bounding box that have groundwater level data during the appropriate time period
fetch_gw_sites <- function(target_name, start_date, end_date, bbox, param_cd){
  
  # From NWIS services documentation: The product of the range of latitude range 
  #   and longitude multiplied cannot exceed 25 degrees. So, we need to cycle through  
  #   large bounding boxes by dividing into query cells. Using 5 x 5 cells
  
  query_bbox_cells <- prep_latlon_cells(bbox[c(1,3)], bbox[c(2,4)], deg_per_slice = 5)
  n_cells <- nrow(query_bbox_cells)
  
  sites <- c()
  for(cell in seq_len(n_cells)) {
    # For CONUS, we expect some to fail with no data since we put a square grid on
    # top of the whole country, which means some cells are only over the oceans.
    message(sprintf("Trying cell %s of %s ...", cell, n_cells))
    sites <- tryCatch(
      whatNWISdata(bBox = extract_cell_bbox(query_bbox_cells, cell), 
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
  
  saveRDS(sites, target_name)
  
}

#' Function to divide the requested bounding box into NWIS query-able cells
prep_latlon_cells <- function(long_vals, lat_vals, deg_per_slice) {
  
  long_slice_vals <- divide_latlon(long_vals, 5, "x")
  lat_slice_vals <- divide_latlon(lat_vals, 5, "y")
  cells <- expand.grid(long_i = seq_len(nrow(long_slice_vals)), lat_i = seq_len(nrow(lat_slice_vals)))
  
  cell_vals <- tibble(
    xmin = long_slice_vals$xmin[cells$long_i],
    ymin = lat_slice_vals$ymin[cells$lat_i],
    xmax = long_slice_vals$xmax[cells$long_i],
    ymax = lat_slice_vals$ymax[cells$lat_i]
  ) %>% 
    rowwise() %>% 
    mutate(bbox = list(c(xmin, ymin, xmax, ymax))) %>% 
    ungroup() # Undo "by row"
  
  # helper code here if you want to visualize the query cells:
  # par(mar = c(0,0,0,0))
  # maps::map('usa')
  # rect(cell_vals$xmin, cell_vals$ymin, cell_vals$xmax, cell_vals$ymax)
  
  return(cell_vals)  
}

#' Helper function applied to either the latitude OR longitude decimal 
#' vectors that divides them into NWIS query-managable sizes
divide_latlon <- function(vals, deg_per_slice, name = c("x", "y")) {
  
  n_slices <- ceiling(diff(vals)/deg_per_slice)
  
  min_val_slice <- min(vals) + (seq_len(n_slices)-1)*deg_per_slice
  max_val_slice <- min(vals) + (seq_len(n_slices))*deg_per_slice
  
  # Correct last slice to be max latitude
  max_val_slice <- ifelse(max_val_slice > max(vals), max(vals), max_val_slice)
  
  slices <- tibble(min_val_slice, max_val_slice)
  names(slices) <- paste0(name, c("min", "max"))
  
  return(slices)
}

#' Helper function to pull out nested bbox vector from 
#' the big table of bbox values per cell
extract_cell_bbox <- function(bbox_df, cell_i) {
  unlist(bbox_df$bbox[cell_i])
}

fetch_gw_site_info <- function(target_name, site_vec_fn) {
  readNWISsite(readRDS(site_vec_fn)) %>% 
    select(site_no, station_nm, state_cd, dec_lat_va, dec_long_va) %>% 
    write_csv(target_name)
}

fetch_gw_data <- function(target_name, site_vec_fn, start_date, end_date, param_cd, stat_cd, request_limit = 10) {
  
  sites <- readRDS(site_vec_fn)
  
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
        statCd = stat_cd) %>%
      rename(GWL := sprintf("X_%s_%s", param_cd, stat_cd)) %>% 
      select(site_no, Date, GWL), 
      # no data returned situation
      error = function(e) return()
    )
    
    gwl_data <- rbind(gwl_data, data_i)
    message(sprintf("Completed pulling gwl data for %s of %s sites", last_site, length(sites)))
  }
  
  gwl_data_unique <- dplyr::distinct(gwl_data) # need this to avoid some duplicates
  
  write_csv(gwl_data_unique, target_name)
  
}
