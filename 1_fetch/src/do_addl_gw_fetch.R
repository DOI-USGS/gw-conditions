do_addl_gw_fetch <- function(final_target, addl_param_cds) {
  # Special pull for just KS & just FL using `62610`. Plus, HI using `72150`.
  # Read all about why on GitHub: https://github.com/USGS-VIZLAB/gw-conditions/issues/9
  
  # Creates this task makefile which then calls `do_gw_fetch()`
  # and makes additional task makefiles for each pcode.
  task_makefile <- '1_fetch_addl_gw_tasktable.yml'
  
  tasks <- unique(addl_param_cds)
  
  
  identify_sites <- create_task_step(
    step_name = 'identify_sites',
    target_name = function(task_name, ...) {
      sprintf('gw_sites_uv_addl_%s', task_name)
    },
    command = function(task_name, ...) {
      sprintf("pull_sites_by_query(gw_quantile_site_info, I('uv'), I('%s'))", task_name)
    }
  )
 
  download_addl_data <- create_task_step(
    step_name = 'download_addl_data',
    target_name = function(task_name, ...) {
      sprintf('1_fetch/tmp/gw_data_uv_addl_%s.csv', task_name)
    },
    command = function(..., task_name, steps) {
      psprintf("do_gw_fetch(",
               "final_target = target_name,",
               "task_makefile = I('1_fetch_tasks_addl.yml'),",
               "gw_site_nums = %s," = steps[['identify_sites']]$target_name,
               "gw_site_nums_obj_nm = I('%s')," = steps[['identify_sites']]$target_name,
               "param_cd = I('%s')," = task_name,
               "service_cd = I('uv'),",
               "request_limit = uv_fetch_size_limit,",
               "'1_fetch/src/do_gw_fetch.R',",
               "'1_fetch/src/fetch_nwis.R',",
               "include_ymls = I('%s')," = task_makefile,
               "gw_site_tz_xwalk_nm = I('gw_quantile_site_tz_xwalk'))")
    }
  )
  
  # Create the task plan
  task_plan <- create_task_plan(
    task_names = tasks,
    task_steps = list(identify_sites, download_addl_data),
    final_steps = "download_addl_data",
    add_complete = FALSE)
  
  # Create the task remakefile
  create_task_makefile(
    task_plan = task_plan,
    makefile = task_makefile,
    include = c('0_config.yml', '1_fetch.yml'),
    sources = c('1_fetch/src/do_addl_gw_fetch.R'),
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
