visualize_cartogram <- function(png_file, width, height, gw_data_date, date) {
  
  p <- ggplot(gw_data_date, aes(x = site_no, y = GWL)) +
    geom_bar(stat = "identity", fill = "white") +
    scale_y_reverse(expand = c(0,0)) + 
    labs(title = "US Well Levels by state",
         subtitle = date,
         x = element_blank(),
         y = element_blank()) +
    theme_minimal() +
    facet_geo(~ state, grid = "us_state_with_DC_PR_grid2", scales = "free",
              strip.position = "bottom") +
    theme(axis.text.x = element_blank(),
          axis.ticks.x = element_blank(),
          axis.line.x = element_blank(),
          axis.line.y = element_blank(),
          panel.grid.major = element_blank(), 
          panel.grid.minor = element_blank(),
          strip.background = element_rect(color = "white"),
          panel.border = element_rect(colour = "grey", fill=NA, size=1),
          panel.background = element_rect(colour = NA, fill="cornflowerblue"))
  
  ggsave(png_file, p, width = width, height = height)
  
}
