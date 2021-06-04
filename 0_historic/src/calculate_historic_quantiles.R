combine_gw_uv_and_dv <- function(out_file, dv_fn, uv_fn) {
  bind_rows(read_csv(dv_fn), read_csv(uv_fn)) %>% 
    write_csv(out_file)
}

# Per gage, calc quantiles using historic groundwater level data (no seasonality)
calculate_historic_quantiles <- function(target_name, historic_gw_data_fn, quantiles_to_calc) {
  
  read_csv(historic_gw_data_fn, col_types = 'cDn') %>% 
    split(.$site_no) %>% 
    map_dfr(., function(.x) {
      quants <- quantile(.x$GWL, quantiles_to_calc, na.rm = TRUE)
      names(quants) <- NULL # Otherwise, carries unnecessary metadata
      tibble(quantile_nm = quantiles_to_calc*100, quantile_va = quants)
    }, .id = "site_no") %>% 
    bind_rows() %>% 
    write_csv(target_name)
  
}
