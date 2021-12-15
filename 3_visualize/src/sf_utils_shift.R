
# Utility functions for shifting

#' @title extract and define shifting criteria
#' @description defines and extracts shifting criteria
#' for six different regions. If the input to `region_abbr`
#' does not match existing definitions, then shifting values
#' are returned which will do nothing to the spatial feature.
#' @param region_abbr a single character string for which
#' region to pull out shifting information for.
get_shift <- function(region_abbr){
  switch(
    region_abbr,
    AK = list(scale = 0.47, shift = c(90,-465), rotation_deg = -50),
    HI = list(scale = 1.5, shift = c(520, -110), rotation_deg = -35),
    # TODO: Shift & scale PR & VI together - currently making 
    # assumptions about how closer together they are. Should treat
    # them as one sf to shift and scale.
    PR = list(scale = 3.15, shift = c(-120,90), rotation_deg=20),
    VI = list(scale = 3.15, shift = c(-80,77), rotation_deg=20),
    GU = list(scale = 10, shift = c(1070, -625), rotation_deg=-90),
    AS = list(scale = 10, shift = c(1050, 0), rotation_deg=-90),
    # If there is no match, default to doing nothing to the object
    list(scale = 1, shift = c(0,0), rotation_deg=0)
  )
}

#' @title create a single sf object for regions outside of CONUS
#' @desciption generate an sf object containing the spatial data 
#' for one or more regions in the `maps` package "world" database. 
#' @param region_abbrs one or more character strings that match the
#' abbreviations listed in the `abbr_xwalk`
#' @param proj_str character string representing the projection
#' @value a single `sf` object with one or more polygons for the 
#' current list of abbreviations
generate_single_oconus_sf <- function(region_abbrs, proj_str) {
  abbr_xwalk <- tibble(
    abbr = c("AK", "HI", "PR", "VI", "GU", "AS"),
    map_name = c("USA:Alaska", "USA:Hawaii", "Puerto Rico", 
                 "Virgin Islands, US", "Guam", "American Samoa")
  )
  
  map_name <- abbr_xwalk %>% 
    filter(abbr %in% region_abbrs) %>% 
    pull(map_name)
  
  # We need more detail than what `maps::map()` can offer, especially
  # for Guam, Virgin Islands, and American Samoa
  obj_sf <- maps::map("world", map_name, fill=TRUE, plot=FALSE) %>%
    sf::st_as_sf() %>% 
    st_transform(proj_str) %>% 
    st_buffer(0)
}

#' @title create a single, shifted sf object for regions outside of CONUS
#' @desciption generate an sf object for regions outside of CONUS that 
#' will be visible in a map view where CONUS is the focus. Currently
#' functions for Alaska (`AK`), Hawaii (`HI`), Puerto Rico (`PR`), the
#' U.S. Virgin Islands (`VI`), Guam (`GU`), and American Samoa (`AS`).
#' @param proj_str character string representing the projection
#' @value a single `sf` object a polygon per region shifted and scaled 
#' to be visible on a CONUS map of the same projection.
build_oconus_sf <- function(proj_str) {
  
   # Might need to treat PR & VI as one
  region_abbr_list <- list(
    "AK",
    "HI",
    "PR", 
    "VI", 
    "GU", 
    "AS"
  )
  
  oconus_sf <- purrr::map(
    region_abbr_list,
    function(region) {
      # Generate the sf object for the current region(s)
      obj_sf <- generate_single_oconus_sf(region, proj_str)
      
      # Get the appropriately matched shifting criteria 
      # Use region[1] so that the `PR` & `VI` shifting criteria only
      # returns one list of shifting criteria.
      shift_criteria <- get_shift(region)
      
      # Apply the shifting criteria to the current `obj_sf`
      obj_sf_shifted <- do.call(shift_sf, c(obj_sf = list(obj_sf), 
                                            shift_criteria, 
                                            proj_str = proj_str))
      return(obj_sf_shifted)
    }
  ) %>% bind_rows()
}

#' @title shift, scale, and rotate an `sf` object
#' @descriptions shifts, scales, and rotates the `sf` object
#' passed in according to the other inputs.
#' @param obj_sf an `sf` object with an existing `crs` that will be
#' transformed and shifted/scaled/rotated.
#' @param rotation_deg numeric value indicating the number of degrees
#' to rotate the object. Positive values rotate the object clockwise;
#' negative values rotate the polygon counterclockwise.
#' @param scale numeric multiplier for how much bigger to make the sf object polygon
#' @param shift numeric vector where the first value is the number of units (depends
#' on the projection being used) to shift the object along longitude (horizontal)
#' and the second value is the number of units to shift the latitude (vertical). Use
#' negative values to shift further West or South.
#' @param proj_str
#' @value an `sf` object that has been shifted, scaled, and rotated. 
shift_sf <- function(obj_sf, rotation_deg, scale, shift, proj_str) {
  
  stopifnot(!is.na(st_crs(obj_sf)))
  
  obj_sf_transf <- st_transform(obj_sf, proj_str)
  obj_sfg <- st_geometry(obj_sf)
  obj_sfg_centroid <- st_centroid(obj_sfg)
  
  # Rotate and scale obj_sf
  obj_sfg_rot_scaled <- (obj_sfg - obj_sfg_centroid) * rot(rotation_deg*pi/180) * scale + obj_sfg_centroid
  
  # Borrowing these fixes to scale & shift from sp code 
  #   See https://github.com/USGS-VIZLAB/gages-through-ages/blob/master/scripts/process/process_map.R#L91
  obj_sfg_centroid_new <- st_centroid(obj_sfg_rot_scaled)
  new_shift <- shift*10000+c(st_coordinates(obj_sfg_centroid)-st_coordinates(obj_sfg_centroid_new))
  
  # Shift obj_sf
  obj_sfg_shifted <- obj_sfg_rot_scaled + new_shift
  
  # Want to return a complete `sf` object, not just the geometry
  # Not features were filtered, the values were just updated, so
  # we can make a copy of `obj_sf` and then insert the updated
  # geometry + add the appropriate projection info
  obj_sf_shifted <- obj_sf # Make a copy
  st_geometry(obj_sf_shifted) <- obj_sfg_shifted
  st_crs(obj_sf_shifted) <- proj_str
  
  return(obj_sf_shifted)
}

#' @title helper function for mathematically rotating a polygon's coordinates. 
#' @description Basic rotation function used in `shift_sf()` to apply to the 
#' coordinates of a polygon. Originally created by Jordan Read. See 
#' https://github.com/USGS-VIZLAB/gages-through-ages/blob/master/scripts/process/process_map.R#L91
#' @param a numeric value in radians for which to rotate a polygon
#' @value a matrix with the multipliers to use in the x and y direction to rotate coordinates
rot <- function(a) matrix(c(cos(a), sin(a), -sin(a), cos(a)), 2, 2)
