# gw-conditions

Show groundwater conditions as little peaks above or below their normal values. Current code will produce:



## Generate the data behind the visualization and push to S3

This step is not needed to build the visualization locally since the data files are available through a public S3 bucket and can be accessed from `labs.waterdata.usgs.gov/visualizations/data/[FILENAME]`. Run this code if you need to update the data or base SVG behind the visualization.

### Build the historic data

The historic data pipeline (`0_historic.yml`) is decoupled from the rest of the pipeline. It will build only when you run `scmake(remake_file = "0_historic.yml")`. Otherwise, the `1_fetch.yml` part of the pipeline will assume the historic data is on S3 ready to use and will download the data using the filepaths described in `0_config.yml`. The historic data is being stored on the developer VPC in the `vizlab-data` bucket but should be moved for public access later if we do a data release. 

### How to build the data behind the viz:

If you plan to be able to push the final data to S3, you need to have the appropriate S3 configs prepared. The file `lib/cfg/s3_config_viz.yml` expects you to have credentials labeled `[prod]` in your `~/.aws/credentials` file (rather than `[default]`). Also note that any of the targets that call `scipiper::s3_put()` will require you to be on the USGS Network (VPN). If you want to build the data pipeline but don't need to (or can't) push to S3, you can run `options(scipiper.dry_put = TRUE)` and then the code listed below. This will skip the upload step.

Once your configurations are set up, run the following to generate the data needed by the visualization. 

```r
library(scipiper)
scmake()
```

In the end the following targets should have been built successfully (because they are what is pushed to S3 and used by the Vue code):

- `visualizations/data/gw-conditions-time-labels.csv.ind`
- `visualizations/data/gw-conditions-peaks-map.svg`
- `visualizations/data/gw-conditions-wy20.csv.ind`
- `visualizations/data/gw-conditions-site-coords.csv.ind`
- `visualizations/data/gw-conditions-daily-proportions.csv.ind`

If you change the `viz_start_date` and `viz_end_date` values in `0_config.yml`, you should also change the name of the `visualizations/data/gw-conditions-wy20.csv.ind` file to reflect your new time period. In the future, we would like to do this automatically, but for now it is a manual step. The Vue code that reads that file would also need to be changed.

## Build the visualization locally

The data (all CSVs and SVGs) needed for this visualization are already publicly available through `labs.waterdata.usgs.gov/visualizations/data/[FILENAME]`. You should be able open this repo, run the following code chunk, and see the visualization locally (http://localhost:8080/) without needed to build the data pipeline:

```
npm install
npm run serve
```
