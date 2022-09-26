# SVG map utils

# Borrowed from https://github.com/usgs-makerspace/wbeep-viz/blob/master/wu_pipeline/6_visualize/src/build_svg_map.R

add_background_map <- function(svg, svg_width, outline_states, digits) {
  map_data <- generate_usa_map_data(outline_states = outline_states)
  
  bkgrd_grp <- xml_add_child(svg, 'g', 
                             id = "bkgrd-map-grp", 
                             class='map-bkgrd')
  purrr::map(map_data$ID, function(polygon_id, map_data, svg_width) {
    d <- map_data %>% 
      filter(ID == polygon_id) %>% 
      convert_coords_to_svg(view_bbox = st_bbox(map_data), svg_width, digits) %>% 
      build_path(connect = TRUE)
    xml_add_child(bkgrd_grp, 'path', 
                  d = d, 
                  class='map-bkgrd')
  }, map_data, svg_width)
  
}

convert_coords_to_svg <- function(sf_obj, svg_width, view_bbox = NULL, digits = 6) {
  
  coords <- st_coordinates(sf_obj)
  x_dec <- coords[,1]
  y_dec <- coords[,2]
  
  # Using the whole view, figure out coordinates
  # If view_bbox isn't provided, assume sf_obj is the whole view
  if(is.null(view_bbox)) view_bbox <- st_bbox(sf_obj)
  
  x_extent <- c(view_bbox$xmin, view_bbox$xmax)
  y_extent <- c(view_bbox$ymin, view_bbox$ymax)
  
  # Calculate aspect ratio
  aspect_ratio <- diff(x_extent)/diff(y_extent)
  
  # Figure out what the svg_height is based on svg_width, maintaining the aspect ratio
  svg_height <- svg_width / aspect_ratio
  
  # Convert longitude and latitude to SVG horizontal and vertical positions
  # Remember that SVG vertical position has 0 on top
  x_extent_pixels <- x_extent - view_bbox$xmin
  y_extent_pixels <- y_extent - view_bbox$ymin
  x_pixels <- x_dec - view_bbox$xmin # Make it so that the minimum longitude = 0 pixels
  y_pixels <- y_dec - view_bbox$ymin # Make it so that the maximum latitude = 0
  
  data.frame(
    x = round(approx(x_extent_pixels, c(0, svg_width), x_pixels)$y, digits),
    y = round(approx(y_extent_pixels, c(svg_height, 0), y_pixels)$y, digits)
  )
}

generate_usa_map_data <- function(proj_str = NULL, outline_states = FALSE) {
  if(is.null(proj_str)) {
    # Albers Equal Area
    proj_str <- "+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=37.5 +lon_0=-96 +x_0=0 +y_0=0 +ellps=GRS80 +datum=NAD83 +units=m +no_defs"
  }
  
  conus_sf <- maps::map("usa", fill = TRUE, plot=FALSE) %>%
    sf::st_as_sf() %>% 
    st_transform(proj_str) %>% 
    st_buffer(0) 
  
  if(outline_states) conus_sf <- use_state_outlines(conus_sf, proj_str)
  
  # Now add oconus ("outside" conus)
  oconus_sf <- build_oconus_sf(proj_str)
  usa_sf <- bind_rows(conus_sf, oconus_sf)
  
  return(usa_sf)
}

use_state_outlines <- function(usa_border_sf, proj_str) {
  
  # Need to remove islands from state outlines and then add back in 
  # later so that they can be drawn as individual polygons. Otherwise,
  # drawn with the state since the original state maps data only has 1
  # ID per state.
  
  usa_islands_sf <- usa_border_sf %>% filter(ID != "main")
  usa_addl_islands_sf <- generate_addl_islands(proj_str)
  usa_mainland_sf <- usa_border_sf %>% 
    filter(ID == "main") %>% 
    st_erase(usa_addl_islands_sf) 
  
  # Have to manually add in CO because in `maps`, it is an incomplete
  # polygon and gets dropped somewhere along the way.
  co_sf <- maps::map("state", "colorado", fill = TRUE, plot=FALSE) %>%
    sf::st_as_sf() %>%
    st_transform(proj_str)
  
  maps::map("state", fill = TRUE, plot=FALSE) %>%
    sf::st_as_sf() %>%
    st_transform(proj_str) %>%
    st_buffer(0) %>% 
    # Get rid of islands from state outline data
    st_intersection(usa_mainland_sf) %>%
    select(-ID.1) %>% # st_intersection artifact that is unneeded
    # Add islands back in as separate polygons from states
    bind_rows(usa_islands_sf) %>%
    bind_rows(usa_addl_islands_sf) %>% 
    st_buffer(0) %>%
    st_cast("MULTIPOLYGON") %>% # Needed to bring back to correct type to use st_coordinates
    rmapshaper::ms_simplify(0.5) %>%
    bind_rows(co_sf) # bind CO after bc otherwise it gets dropped in st_buffer(0)
  
}

generate_addl_islands <- function(proj_str) {
  # These are not called out specifically as islands in the maps::map("usa") data
  # but cause lines to be drawn across the map if not treated separately. This creates those shapes.
  
  # Counties to be considered as separate polygons
  
  separate_polygons <- list(
    `upper penninsula` = list(
      state = "michigan",
      counties = c(
        "alger",
        "baraga",
        "chippewa",
        "delta",
        "dickinson",
        "gogebic",
        "houghton",
        "iron",
        "keweenaw",
        "luce",
        "mackinac",
        "marquette",
        "menominee",
        "ontonagon",
        "schoolcraft"
      )),
    `eastern shore` = list(
      state = "virginia",
      counties = c(
        "accomack",
        "northampton"
      )),
    # TODO: borders still slightly wonky bc it doesn't line up with counties perfectly. 
    `nags head` = list(
      state = "north carolina",
      counties = c(
        "currituck"
      )),
    # This + simplifying to 0.5 took care of the weird line across NY
    `staten island` = list(
      state = "new york",
      counties = c(
        "richmond"
      )))
  
  purrr::map(names(separate_polygons), function(nm) {
    maps::map("county", fill = TRUE, plot=FALSE) %>%
      sf::st_as_sf() %>%
      st_transform(proj_str) %>% 
      st_buffer(0) %>%
      filter(ID %in% sprintf("%s,%s", separate_polygons[[nm]][["state"]],
                             separate_polygons[[nm]][["counties"]])) %>% 
      mutate(ID = nm) 
  }) %>% 
    bind_rows() %>% 
    group_by(ID) %>% 
    summarize(geom = st_union(geom))
}

list_state_counties <- function(state_abbr) {
  tolower(gsub(" County", "", countyCd$COUNTY_NAME[which(countyCd$STUSAB == state_abbr)]))
}

st_erase <- function(x, y) st_difference(x, st_union(st_combine(y)))
