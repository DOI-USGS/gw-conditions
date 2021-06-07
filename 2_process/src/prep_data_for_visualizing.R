
add_paths_to_data <- function(data_in) {
  data_in %>% mutate(path = build_path_peak(daily_quant))
}

add_colors_to_data <- function(data_in, scico_palette_nm = "roma") {
  # Create 5 color palette
  col_palette <- rev(scico::scico(5, palette = scico_palette_nm))
  
  data_in %>% 
    # Add number 1:365 for day of water year for each site
    group_by(site_no) %>% 
    arrange(Date) %>% 
    mutate(wyday = row_number()) %>% 
    ungroup() %>% 
    # Add color based on quantile category
    mutate(color = ifelse(
      quant_category == "Very high",
      yes = col_palette[1], no = ifelse(
        quant_category == "High",
        yes = col_palette[2], no = ifelse(
          quant_category == "Normal",
          yes = col_palette[3], no = ifelse(
            quant_category == "Low",
            yes = col_palette[4], no = ifelse(
              quant_category == "Very low",
              yes = col_palette[5], no = "black"))))))
}
