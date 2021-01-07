# gw-conditions
Similar to gage-conditions-gif but for groundwater!

### DISCLAIMER: 

THE ANALYSIS IN THIS VIZ REPO (AS IT CURRENTLY STANDS 12/23/2020) IS NOT MEANT TO BE FINAL. JUST USED AS AN EXAMPLE OF HOW TO BUILD A VIDEO-BASED DATAVIZ USING SCIPIPER

### How to build the viz:

To build, check the `start_date` and `end_date` in `0_config.yml`. Then, run the following and look in your `4_animate/out` folder for the video.

```r
library(scipiper)
scmake()
```

### How to get Climate Response Network data:

```r
library(scipiper)
scmake("1_fetch/out/gw_crn_data.rds")
crn_data <- readRDS("1_fetch/out/gw_crn_data.rds")
```
