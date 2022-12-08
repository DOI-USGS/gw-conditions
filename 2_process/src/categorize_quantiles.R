
categorize_quantiles <- function(target_name, quantile_data_fn, anomaly_bins, anomaly_categories) {

  anomaly_bins <- scmake("anomaly_bins")
  anomaly_categories <- scmake("anomaly_categories")
  
  read_csv(quantile_data_fn, col_types = 'cDnn') %>% 
    mutate(quant_category = cut(daily_quant, 
                                breaks = anomaly_bins, 
                                labels = anomaly_categories, 
                                include.lowest = TRUE)) %>% 
    write_csv(target_name)
  
}
