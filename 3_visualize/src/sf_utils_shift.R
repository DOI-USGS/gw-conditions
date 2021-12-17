
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
    AK = list(scale = 0.75, shift = c(-30,-200), rotation_deg = -40),
    HI = list(scale = 1.75, shift = c(300, 0), rotation_deg = -35),
    PR = list(scale = 3.15, shift = c(-95,75), rotation_deg=20),
    VI = list(scale = 4, shift = c(-115,110), rotation_deg=20),
    GU = list(scale = 5, shift = c(725, -575), rotation_deg=-90),
    AS = list(scale = 5, shift = c(675, -30), rotation_deg=-45),
    MP = list(scale = 1.5, shift = c(815,-600), rotation_deg=0),
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
  
  if("AK" %in% region_abbrs) {
    # If we are plotting AK, use the low-res version (and by 
    # function simplicity, do any regions grouped with AK as 
    # the low-res version, too)
    ak_sf <- maps::map("world", "USA:Alaska", fill=TRUE, plot=FALSE) %>%
      sf::st_as_sf() %>% 
      st_transform(proj_str) %>% 
      mutate(ID = "AK")
    
    # Scrub AK out of the list now
    region_abbrs <- region_abbrs[!grepl("AK", region_abbrs)]
  } 
  
  # If there were more `region_abbrs` passed in beyond just AK
  # then use the high-res spatial data for those
  if(length(region_abbrs) > 0) {
    # Note that every time you call this function, it will load the
    # high-resolution spatial shapefile.
    regions_sf <- st_read('2_process/out/nws_states.shp') %>% 
      select(ID = STATE) %>% 
      filter(ID %in% region_abbrs) %>% 
      rename(geom = geometry) %>% 
      st_transform(proj_str)
  }
  
  if(exists("ak_sf") & exists("regions_sf")) {
    return(bind_rows(ak_sf, regions_sf))
  } else if(exists("ak_sf") & !exists("regions_sf")) {
    return(ak_sf)
  } else if(!exists("ak_sf") & exists("regions_sf")){
    return(regions_sf)
  }
}

#' @title create a single, shifted sf object for regions outside of CONUS
#' @desciption generate an sf object for regions outside of CONUS that 
#' will be visible in a map view where CONUS is the focus. Currently
#' functions for Alaska (`AK`), Hawaii (`HI`), Puerto Rico (`PR`), the
#' U.S. Virgin Islands (`VI`), Guam (`GU`), American Samoa (`AS`), and
#' the Northern Marianas (`MP`).
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
    "AS",
    "MP"
  )
  
  oconus_sf_noshift <- generate_single_oconus_sf(unlist(region_abbr_list), proj_str)
  
  oconus_sf <- purrr::map(
    region_abbr_list,
    function(region) {
      # Generate the sf object for the current region(s)
      obj_sf <- filter(oconus_sf_noshift, ID %in% region)
      
      # Get the appropriately matched shifting criteria 
      # Use region[1] so that the `PR` & `VI` shifting criteria only
      # returns one list of shifting criteria.
      shift_criteria <- get_shift(region)
      
      # Apply the shifting criteria to the current `obj_sf`
      obj_sf_shifted <- do.call(shift_sf, c(obj_sf = list(obj_sf), 
                                            shift_criteria, 
                                            proj_str = proj_str))
      
      # For drawing SVGs, we need POLYGONs not MULTIPOLYGONs returned
      obj_sf_shifted_poly <- obj_sf_shifted %>% 
        st_cast("POLYGON") %>% 
        mutate(ID = sprintf("%s_%s", ID, row_number()))
      
      return(obj_sf_shifted_poly)
    }
  ) %>% bind_rows()
  return(oconus_sf)
}

#' @title shift, scale, and rotate an `sf` object
#' @descriptions shifts, scales, and rotates the `sf` object
#' passed in according to the other inputs.
#' @param obj_sf an `sf` object with POLYGON or MULTIPOLYGON geometry. Should
#' have a `crs` that will be transformed and shifted/scaled/rotated.
#' @param rotation_deg numeric value indicating the number of degrees
#' to rotate the object. Positive values rotate the object clockwise;
#' negative values rotate the polygon counterclockwise.
#' @param scale numeric multiplier for how much bigger to make the sf object polygon
#' @param shift numeric vector where the first value is the number of units (depends
#' on the projection being used) to shift the object along longitude (horizontal)
#' and the second value is the number of units to shift the latitude (vertical). Use
#' negative values to shift further West or South.
#' @param proj_str character string representing the projection to use
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

#' @title Use shifting information and polygons to also shift sites
#' @description Apply the same shifting criteria that was used for the 
#' polygons to move the site locations for any site that is in one of
#' the O-CONUS ("outside CONUS") regions.
#' @param sites_sf an `sf` object with at lease a `site_no` column
#' @param sites_info a data.frame with at least a `site_no` and a
#' `state_cd` column.
#' @param proj_str character string representing the projection to use
#' @value an updated `sf` object with a location for every site that 
#' matches the locations of the region they are in, include shifted ones.
apply_shifts_to_sites <- function(sites_sf, sites_info, proj_str) {
  
  oconus_abbr_list <- list(
    "AK",
    "HI",
    "PR", 
    "VI", 
    "GU",
    "AS",
    "MP"
  )
  
  sites_abbr_xwalk <- sites_info %>% 
    mutate(state_abbr = dataRetrieval::stateCdLookup(state_cd)) %>% 
    select(site_no, state_abbr) 
  sites_sf_with_abbr <- sites_sf %>% left_join(sites_abbr_xwalk)
  
  # Separate sites in CONUS vs O-CONUS
  conus_sites_sf <- sites_sf_with_abbr %>% filter(!state_abbr %in% oconus_abbr_list)
  oconus_sites_sf <- sites_sf_with_abbr %>% filter(state_abbr %in% oconus_abbr_list)
  
  # Only shift sites that are in one of those shifted regions:
  oconus_site_sf_shifted <- purrr::map(
    c("VI","PR","AK","HI"),
    function(region) {
      # Generate the sf object for the current region(s)
      pts_sf <- filter(oconus_sites_sf, state_abbr %in% region)
      
      # Generate the matching polygon to use as a reference when scaling
      ref_sf <- generate_single_oconus_sf(region, proj_str)
      
      # Get the appropriately matched shifting criteria 
      # Use region[1] so that the `PR` & `VI` shifting criteria only
      # returns one list of shifting criteria.
      shift_criteria <- get_shift(region)
      
      # Apply the shifting criteria to the current `obj_sf`
      obj_sf_shifted <- do.call(shift_points_sf, c(pts_sf = list(pts_sf), 
                                                   shift_criteria, 
                                                   proj_str = proj_str,
                                                   ref_sf = list(ref_sf)))
      return(obj_sf_shifted)
    }
  ) %>% bind_rows() 
  
  # Combine all sites back together
  sites_sf_complete <- conus_sites_sf %>% 
    bind_rows(oconus_site_sf_shifted)
  return(sites_sf_complete)
}

#' @title shift, scale, and rotate an `sf` object
#' @descriptions shifts, scales, and rotates the `sf` object
#' passed in according to the other inputs.
#' @param pts_sf an `sf` object with POINT or MULTIPOINT geometry. Should
#' have a `crs` that will be transformed and shifted/scaled/rotated.
#' @param rotation_deg numeric value indicating the number of degrees
#' to rotate the object. Positive values rotate the object clockwise;
#' negative values rotate the polygon counterclockwise.
#' @param scale numeric multiplier for how much bigger to make the sf object polygon
#' @param shift numeric vector where the first value is the number of units (depends
#' on the projection being used) to shift the object along longitude (horizontal)
#' and the second value is the number of units to shift the latitude (vertical). Use
#' negative values to shift further West or South.
#' @param proj_str character string representing the projection to use
#' @param ref_sf if scaling relative to a polygon, you need to pass in the
#' polygon to use its centroid to appropriate scale the points
#' @value an `sf` object that has been shifted, scaled, and rotated. 
shift_points_sf <- function(pts_sf, rotation_deg, scale, shift, proj_str, ref_sf = NULL) {
  
  stopifnot(!is.na(st_crs(pts_sf)))
  
  pts_sf_transf <- st_transform(pts_sf, proj_str)
  pts_sfg <- st_geometry(pts_sf)
  
  # Apply rotation & scaling
  if(!is.null(ref_sf)) {
    scaling_center <- st_coordinates(st_centroid(ref_sf))
  } else {
    scaling_center <- find_pts_centroid(pts_sfg_rot)
  }
  pts_sfg_rot_scaled <- (pts_sfg - scaling_center) * rot(rotation_deg*pi/180) * scale + scaling_center
  
  # Apply shifting
  pts_sfg_shifted <- pts_sfg_rot_scaled + shift*10000
  
  # Want to return a complete `sf` object, not just the geometry
  # No features were filtered, the values were just updated, so
  # we can make a copy of `pts_sf` and then insert the updated
  # geometry + add the appropriate projection info
  pts_sf_shifted <- pts_sf # Make a copy
  st_geometry(pts_sf_shifted) <- pts_sfg_shifted
  st_crs(pts_sf_shifted) <- proj_str
  
  return(pts_sf_shifted)
}

#' @title helper function for mathematically rotating a polygon's coordinates. 
#' @description Basic rotation function used in `shift_sf()` to apply to the 
#' coordinates of a polygon. Originally created by Jordan Read. See 
#' https://github.com/USGS-VIZLAB/gages-through-ages/blob/master/scripts/process/process_map.R#L91
#' @param a numeric value in radians for which to rotate a polygon
#' @value a matrix with the multipliers to use in the x and y direction to rotate coordinates
rot <- function(a) matrix(c(cos(a), sin(a), -sin(a), cos(a)), 2, 2)

#' @title Find the centroid of a set of points
#' @description Determine the centroid of a set of
#' points from an sf object by average the x and y
#' coordinates. Return as an sf POINT object. You
#' can use this as the center of scaling and rotation.
#' @param pts_sf an sf object with POINT or MULTIPOINT geometry
find_pts_centroid <- function(pts_sf) {
  st_coordinates(pts_sf) %>% 
    apply(2, mean) %>%
    t() %>% as.data.frame() %>% 
    st_as_sf(coords = c("X", "Y")) %>% 
    st_geometry()
}
