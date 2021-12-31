do_historic_addl_param_fetch <- function(final_target, addl_states, addl_gw_param_cds, 
                                         historic_start_date, historic_end_date) {
  # Special pull for just KS & just FL using `62610`. Plus, HI using `72150`.
  # Read all about why on GitHub: https://github.com/USGS-VIZLAB/gw-conditions/issues/9
  
  # Creates this task makefile which then calls `do_historic_gw_fetch()`
  # and makes additional task makefiles for each pcode.
  task_makefile <- '0_historic_addl_fetch_tasktable.yml'
  
  fetch_cfg <- tibble(
    param_cd = addl_gw_param_cds,
    state_cd = addl_states
  ) 
  tasks <- unique(fetch_cfg$param_cd)
  
  identify_states <- create_task_step(
    step_name = 'identify_states',
    target_name = function(task_name, ...) {
      sprintf('addl_states_%s', task_name)
    },
    command = function(task_name, ...) {
      states <- filter(fetch_cfg, param_cd == task_name) %>% pull(state_cd)
      sprintf("c(%s)", paste(sprintf("I('%s')", states), collapse = ", "))
    }
  )
  
  inventory_sites <- create_task_step(
    step_name = 'inventory_sites',
    target_name = function(task_name, ...) {
      sprintf('addl_site_nums_%s', task_name)
    },
    command = function(..., task_name, steps) {
      sprintf("fetch_addl_uv_sites(%s, I('%s'), historic_start_date, historic_end_date)", 
              steps[["identify_states"]]$target_name, task_name)
    }
  )

  # Need local timezones for averaging to daily values
  create_addl_sites_tz_xwalk <- create_task_step(
    step_name = 'sites_tz_xwalk',
    target_name = function(task_name, ...) {
      sprintf('addl_sites_tz_xwalk_%s', task_name)
    },
    command = function(..., task_name, steps) {
      sprintf("fetch_gw_site_tz(%s)", steps[['inventory_sites']]$target_name)
    }
  )
  
  download_addl_data <- create_task_step(
    step_name = 'download_addl_data',
    target_name = function(task_name, ...) {
      sprintf('0_historic/tmp/historic_gw_data_uv_addl_%s.csv', task_name)
    },
    command = function(..., task_name, steps) {
      psprintf("do_historic_gw_fetch(",
               "final_target = target_name,",
               "task_makefile = I('0_historic_fetch_tasks.yml'),",
               "gw_site_nums = %s," = steps[['inventory_sites']]$target_name,
               "gw_site_nums_obj_nm = I('%s')," = steps[['inventory_sites']]$target_name,
               "param_cd = I('%s')," = task_name,
               "service_cd = I('uv'),",
               "request_limit = historic_uv_fetch_size_limit,",
               "'0_historic/src/do_historic_gw_fetch.R',",
               "'0_historic/src/fetch_nwis_historic.R',",
               "include_ymls = I('%s')," = task_makefile,
               "gw_site_tz_xwalk_nm = I('%s'))" = steps[['sites_tz_xwalk']]$target_name)
    }
  )
  
  # Create the task plan
  task_plan <- create_task_plan(
    task_names = tasks,
    task_steps = list(identify_states, inventory_sites, download_addl_data),
    final_steps = "download_addl_data",
    add_complete = FALSE)
  
  # Create the task remakefile
  create_task_makefile(
    task_plan = task_plan,
    makefile = task_makefile,
    include = c('0_historic.yml'),
    sources = c('0_historic/src/do_historic_addl_param_fetch.R'),
    packages = c('tidyverse', 'dataRetrieval', 'scipiper', 'purrr'),
    final_targets = final_target,
    finalize_funs = 'combine_addl_gw_files',
    as_promises = TRUE,
    tickquote_combinee_objects = TRUE)
  
  # Build the tasks
  loop_tasks(task_plan = task_plan,
             task_makefile = task_makefile,
             num_tries = 3, # Try a few times, there could be some internet flakiness
             n_cores = 1) # Only one core! Don't want to overwhelm NWIS services
  
  # Clean up files created
  
  # Remove the temporary target from remake's DB; it won't necessarily be a unique  
  #   name and we don't need it to persist, especially since killing the task yaml
  scdel(sprintf("%s_promise", basename(final_target)), remake_file=task_makefile)
  # Delete task makefile since it is only needed internally for this function and  
  #   not needed at all once loop_tasks is complete. Also delete temporary files
  #   saved in order to decouple task makefile from `remake.yml`.
  file.remove(task_makefile)
  
}

combine_addl_gw_files <- function(target_name, ...) {
  purrr::map(list(...), function(fn) read_csv(fn)) %>% 
    bind_rows() %>% 
    readr::write_csv(target_name)
}

pull_site_nums <- function(file_in) {
  read_csv(file_in) %>%
    pull(site_no) %>% 
    unique()
}
