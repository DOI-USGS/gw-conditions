

build_path <- function(xy_df, connect = FALSE) {
  
  x <- xy_df$x
  y <- xy_df$y
  
  # Build path
  first_pt_x <- head(x, 1)
  first_pt_y <- head(y, 1)
  
  all_other_pts_x <- tail(x, -1)
  all_other_pts_y <- tail(y, -1)
  path_ending <- ""
  if(connect) {
    # Connect path to start to make polygon
    all_other_pts_x <- c(all_other_pts_x, first_pt_x)
    all_other_pts_y <- c(all_other_pts_y, first_pt_y)
    path_ending <- " Z"
  }
  
  d <- sprintf("M%s %s %s%s", first_pt_x, first_pt_y,
               paste0("L", all_other_pts_x, " ", 
                      all_other_pts_y, collapse = " "),
               path_ending)
  return(d)
}

build_path_peak <- function(y_val) {
  
  # This built on the assumption that y_max is between 0 and 100.
  # And that "positive" peaks are > 50
  # And "negative" peaks are < 50
  y_peak <- round(50-y_val, digits = 0)
  
  d_curve <- sprintf("M-10 0 C -10 0 0 %s 10 0 Z", y_peak)
  
  return(d_curve)
}
