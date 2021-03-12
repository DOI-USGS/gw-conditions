# Per gage, calc quantiles using historic groundwater level data (no seasonality)
calculate_historic_quantiles <- function(target_name, historic_gw_data, quantiles_to_calc) {
  
  read_csv("0_historic/out/historic_gw_data.csv", col_types = 'cDn') %>% 
    split(.$site_no) %>% 
    map_dfr(., function(.x) {
      quants <- quantile(.x$GWL, quantiles_to_calc, na.rm = TRUE)
      names(quants) <- NULL # Otherwise, carries unnecessary metadata
      tibble(quantile_nm = quantiles_to_calc*100, quantile_va = quants)
    }, .id = "site_no") %>% 
    bind_rows() %>% 
    write_csv(target_name)
  
}
