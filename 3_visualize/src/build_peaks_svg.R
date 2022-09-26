
build_peaks_svg <- function(out_file, svg_width, svg_height, digits = 6, aria_title, aria_desc) {
  
  svg_root <- init_svg(viewbox_dims = c(0, 0, svg_width=svg_width, svg_height=svg_height),
                       aria_title, aria_desc)
  
  add_background_map(svg_root, svg_width = svg_width, outline_states = FALSE, digits)
  
  xml2::write_xml(svg_root, file = out_file)
}
