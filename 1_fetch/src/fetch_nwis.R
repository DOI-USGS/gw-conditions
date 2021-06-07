
pull_sites_by_service <- function(site_df, service) {
  site_df %>% filter(data_type_cd == service) %>% pull(site_no)
}

fetch_gw_dv <- function(target_name, gw_sites, start_date, end_date, param_cd) {
  readNWISdv(
    siteNumbers = gw_sites,
    startDate = start_date,
    endDate = end_date,
    parameterCd = param_cd,
    statCd = "00003") %>%
    rename(GWL := sprintf("X_%s_00003", param_cd)) %>% 
    select(site_no, Date, GWL) %>% 
    distinct() %>% # need this to avoid some duplicates
    write_feather(target_name)
}

fetch_gw_uv <- function(target_name, gw_sites, start_date, end_date, param_cd) {
  readNWISuv(
    siteNumbers = gw_sites,
    startDate = start_date,
    endDate = end_date,
    parameterCd = param_cd) %>%
    rename(GWL_inst := sprintf("X_%s_00000", param_cd)) %>% 
    distinct() %>% # need this to avoid some duplicates
    write_feather(target_name)
}

convert_uv_to_dv <- function(target_name, gw_uv_data_fn) {
  read_feather(gw_uv_data_fn) %>% 
    mutate(Date = as.Date(dateTime)) %>% 
    group_by(site_no, Date) %>% 
    summarize(GWL = mean(GWL_inst, na.rm = TRUE)) %>% 
    write_feather(target_name)
}

combine_gw_uv_and_dv <- function(target_name, dv_fn, uv_fn) {
  bind_rows(read_csv(dv_fn, col_types = 'cDn'), 
            read_csv(uv_fn, col_types = 'cDn')) %>% 
    write_csv(target_name)
}
