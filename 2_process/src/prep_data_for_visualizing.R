
add_paths_to_data <- function(data_in) {
  data_in %>% mutate(path = build_path_peak(daily_quant))
}

add_colors_to_data <- function(data_in, scico_palette_nm = "roma", gw_time) {
  # Create 5 color palette
  col_palette <- rev(scico::scico(5, palette = scico_palette_nm))
  
  date_full <- data_in %>%
    # create a row for every date x site
    expand(Date, site_no) %>%
    distinct()
  
  # bind data to full date sequence so data are complete for each site even with missing data
  # this prevents misalignment of dates and animation sequence in later steps
  gw_time %>%
    left_join(date_full) %>%
    left_join(data_in) %>% 
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
  date_start <- min(data_in$Date)
  date_end <- max(data_in$Date)
  
  time_df <- tibble(Date = seq.Date(from = date_start,
           to = date_end,
           by = "1 day")) %>%
    mutate(day_seq = dplyr::row_number(.))
  
  return(time_df)
  
}
generate_months <- function(file_out, data_in){
  # create data to drive annotations on the timeline
  # this includes month and year labels
  data_in %>%
    mutate(month = lubridate::month(Date),
           month_label = lubridate::month(Date, label = TRUE),
           year = lubridate::year(Date)) %>%
    group_by(month, month_label, year) %>% 
    # draw month labels to the first day of the month
    filter(day_seq == min(day_seq)) %>% 
    ungroup() %>%
    group_by(year) %>%
    # label years on first month they appear
    mutate(year_label = ifelse(day_seq == min(day_seq), year, NA)) %>% 
    write_csv(file_out)
}

# Make sure the data being displayed and used to create labels 
# fits within the time range asked for
# Filter out sites w/ all NA GWL levels
subset_to_date_range <- function(file_out, daily_data_fn, start_date, end_date) {
  read_csv(daily_data_fn) %>% 
    filter(Date >= start_date,
           Date <= end_date) %>% 
    group_by(site_no) %>%
    filter(!all(is.na(GWL))) %>%
    write_csv(file_out)
}
