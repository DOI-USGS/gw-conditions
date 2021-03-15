do_historic_gw_fetch <- function(final_target, task_makefile, gw_site_nums, request_limit, ...) {
  
  # Number indicating how many sites to include per dataRetrieval request to prevent
  # errors from requesting too much at once. More relevant for surface water requests.
  req_bks <- seq(1, length(gw_site_nums), by=request_limit)
  
  tasks <- tibble(i_start = req_bks,
                  i_end = req_bks + request_limit-1) %>% 
    # fix i_end to stop at the actual last value
    mutate(i_end = ifelse(i_end > length(gw_site_nums), length(gw_site_nums), i_end),
           task_id = sprintf("%04d_to_%04d", i_start, i_end))
  
  site_sequence <- create_task_step(
    step_name = 'site_sequence',
    target_name = function(task_name, ...) {
      sprintf('sites_i_%s', task_name)
    },
    command = function(task_name, ...) {
      task_df <- filter(tasks, task_id == task_name)
      sprintf("%s:%s", task_df$i_start, task_df$i_end)
    }
  )
  
  subset_sites <- create_task_step(
    step_name = 'subset_sites',
    target_name = function(task_name, ...) {
      sprintf('gw_sites_%s', task_name)
    },
    command = function(..., task_name, steps) {
      sprintf("historic_gw_sites[%s]", steps[["site_sequence"]]$target_name)
    }
  )
  
  download_data <- create_task_step(
    step_name = 'download_data',
    target_name = function(task_name, ...) {
      sprintf("0_historic/tmp/historic_data_%s.feather", task_name)
    },
    command = function(..., task_name, steps) {
      psprintf("fetch_gw_historic(",
               "target_name = target_name,",
               "gw_sites = %s," = steps[["subset_sites"]]$target_name,
               "start_date = historic_start_date,",
               "end_date = historic_end_date,",
               "param_cd = gw_param_cd,",
               "stat_cd = I('00003'))")
    }
  )
  
  # Create the task plan
  task_plan <- create_task_plan(
    task_names = tasks$task_id,
    task_steps = list(site_sequence, subset_sites, download_data),
    final_steps = c('download_data'),
    add_complete = FALSE)
  
  # Create the task remakefile
  create_task_makefile(
    task_plan = task_plan,
    makefile = task_makefile,
    include = c('0_historic.yml'),
    sources = c(...),
    packages = c('tidyverse', 'dataRetrieval', 'scipiper', 'feather', 'purrr'),
    final_targets = final_target,
    finalize_funs = 'combine_gw_files',
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

combine_gw_files <- function(target_name, ...) {
  purrr::map(list(...), function(fn) read_feather(fn)) %>% 
    bind_rows() %>% 
    readr::write_csv(target_name)
}
