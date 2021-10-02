
add_paths_to_data <- function(data_in) {
  data_in %>% mutate(path = build_path_peak(daily_quant))
}

add_colors_to_data <- function(data_in, scico_palette_nm = "roma", gw_time) {
  # Create 5 color palette
  col_palette <- rev(scico::scico(5, palette = scico_palette_nm))
  
  date_full <- data_in %>%
    # create a row for every date x site
    mutate(site_no = as.character(site_no)) %>%
    expand(Date, site_no) %>%
    distinct()
  
  gw_time %>%
    left_join(date_full) %>%
    left_join(data_in %>% mutate(site_no = as.character(site_no))) %>% 
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
generate_time <- function(data_in) {
  date_start <- min(gw_anomaly_data$Date)
  date_end <- max(gw_anomaly_data$Date)
  
  time_df <- tibble(Date = seq.Date(from = date_start,
           to = date_end,
           by = "1 day")) %>%
    mutate(day_seq = as.numeric(rownames(.))) %>%
    arrange(day_seq)
  
  return(time_df)
  
}
generate_months <- function(file_out, data_in){
  data_in %>%
    mutate(month = lubridate::month(Date),
           month_label = lubridate::month(Date, label = TRUE),
           year = lubridate::year(Date)) %>%
    group_by(month, month_label, year) %>% 
    filter(day_seq == min(day_seq)) %>% ## find the first day of each month to draw labels
    write_csv(file_out)
}