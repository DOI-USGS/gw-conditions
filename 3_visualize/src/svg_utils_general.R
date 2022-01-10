
init_svg <- function(viewbox_dims, aria_title, aria_desc) {
  # create the main "parent" svg node. This is the top-level part of the svg
  svg_root <- xml_new_root('svg', viewBox = paste(viewbox_dims, collapse=" "), 
                           preserveAspectRatio="xMidYMid meet", 
                           xmlns="http://www.w3.org/2000/svg", 
                           `xmlns:xlink`="http://www.w3.org/1999/xlink", 
                           version="1.1",
                           `aria-labelledby`="mapTitleID mapDescID",
                           role="img") 
  xml_add_child(svg_root, 
                "title", 
                id = "mapTitleID",
                aria_title)
  xml_add_child(svg_root, 
                "desc", 
                id = "mapDescID",
                aria_desc)
  return(svg_root)
}

add_grp <- function(svg_root, grp_nm, trans_x, trans_y) {
  xml_add_child(svg_root, 'g', id = grp_nm, 
                transform = sprintf("translate(%s %s) scale(0.35, 0.35)", trans_x, trans_y))
}
