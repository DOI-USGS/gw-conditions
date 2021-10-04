
build_peaks_svg <- function(out_file, svg_width, svg_height) {
  
  svg_root <- init_svg(viewbox_dims = c(0, 0, svg_width=svg_width, svg_height=svg_height))
  
  add_background_map(svg_root, svg_width = svg_width, outline_states = FALSE)
  
  xml2::write_xml(svg_root, file = out_file)
}
