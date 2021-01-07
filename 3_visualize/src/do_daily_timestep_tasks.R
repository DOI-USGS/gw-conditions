
do_daily_timestep_tasks <- function(final_target, start_date, end_date, ...) {
  
  # Define task table rows
  tasks <- tibble(
    task_date = seq(start_date, end_date, by = 1),
    task_datestr = format(task_date, "%Y%m%d"))
  
  # Define task table columns
  filter_gw_data <- create_task_step(
    step_name = 'filter_gw_data',
    target_name = function(task_name, step_name, ...){
      sprintf("gw_data_%s", task_name)
    },
    command = function(task_name, ...){
      task_date <- filter(tasks, task_datestr == task_name) %>% pull(task_date)
      sprintf("filter_data(gw_data_w_site_info, I('%s'))", task_date)
    } 
  )
  
  create_cartogram <- create_task_step(
    step_name = 'create_cartogram',
    target_name = function(task_name, step_name, ...){
      sprintf("3_visualize/tmp/cartogram_bars_%s.png", task_name)
    },
    command = function(task_name, steps, ...){
      task_date <- filter(tasks, task_datestr == task_name) %>% pull(task_date)
      sprintf("visualize_cartogram(target_name, width, height, %s, I('%s'))", 
              steps[["filter_gw_data"]]$target_name, task_date)
    } 
  )
  
  # Create the task plan
  task_plan <- create_task_plan(
    task_names = tasks$task_datestr,
    task_steps = list(filter_gw_data, create_cartogram),
    final_steps = c('create_cartogram'),
    add_complete = FALSE)
  
  # Create the task remakefile
  task_makefile <- '3_visualize_timestep_tasks.yml'
  create_task_makefile(
    task_plan = task_plan,
    makefile = task_makefile,
    include = 'remake.yml',
    sources = c(...),
    packages = c('ggplot2', 'geofacet', 'dplyr'),
    final_targets = final_target,
    as_promises = TRUE,
    tickquote_combinee_objects = TRUE)
  
  # Build the tasks
  loop_tasks(task_plan = task_plan,
             task_makefile = task_makefile,
             num_tries = 1,
             n_cores = 1)
  
  # Clean up files created
  
  # Remove the temporary target from remake's DB; it won't necessarily be a unique  
  #   name and we don't need it to persist, especially since killing the task yaml
  scdel(sprintf("%s_promise", basename(final_target)), remake_file=task_makefile)
  # Delete task makefile since it is only needed internally for this function and  
  #   not needed at all once loop_tasks is complete
  file.remove(task_makefile)
  
}

filter_data <- function(data, date) {
  filter(data, Date == as.Date(date))
}
