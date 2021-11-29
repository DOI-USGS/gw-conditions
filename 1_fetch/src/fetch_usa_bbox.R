
# Default is to use all US states and territories
# Specify a specific region by passing in a vector of states to `states`
fetch_usa_bbox <- function(states = NULL, conus_only = FALSE, states_only = FALSE) {
  # This was a useful resource: https://anthonylouisdagostino.com/bounding-boxes-for-all-us-states/
  # Must be west longitude, south latitude, east longitude, and then north latitude
  
  readr::read_csv("https://gist.githubusercontent.com/a8dx/2340f9527af64f8ef8439366de981168/raw/81d876daea10eab5c2675811c39bcd18a79a9212/US_State_Bounding_Boxes.csv",
                  col_types = cols()) %>% 
    {
      # If `states` is provided, just use that
      if(!is.null(states)) 
        filter(., STUSPS %in% states) 
      else 
        
      {if(conus_only) filter(., !STUSPS %in% c(
        "AK", # Alaska (xmin = -179 & xmax = +179)
        "HI", # Hawaii
        "AS", # American Samoa
        "GU", # Guam
        "MP", # Commonwealth of the Northern Mariana Islands
        "PR", # Puerto Rico
        "VI"  # U.S. Virgin Islands
      )) else .} %>%
        {if(states_only) filter(., !STUSPS %in% c(
          "AS", # American Samoa
          "GU", # Guam
          "MP", # Commonwealth of the Northern Mariana Islands
          "PR", # Puerto Rico
          "VI"  # U.S. Virgin Islands
        )) else .}
        
      } %>% 
    summarize(
      bbox_xmin = min(xmin),
      bbox_ymin = min(ymin),
      bbox_xmax = max(xmax),
      bbox_ymax = max(ymax)
    ) %>% t() %>% as.vector()
    
}
