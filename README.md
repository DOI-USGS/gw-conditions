# gw-conditions

A visualization showing groundwater conditions as little peaks above or below their normal values. This visualization is built using an R-based pipeline for data processing, and Vue.js + D3.js to create an animated site. The R-based pipeline (1) calculates daily percentiles for each well based on the historic record at each site, and (2) writes an svg map for the base of the animation. The R-based pipeline also pushes the data up to a public S3 bucket. This pipeline leverages an internal package, `library(scipiper)` to automate the workflow. You do not need to run the pipeline to be able to build the app locally, since the app points to data in the S3 bucket.

## Build the visualization locally

The data (all CSVs and SVGs) needed for this visualization are already publicly available through `labs.waterdata.usgs.gov/visualizations/data/[FILENAME]`. You should be able open this repo, run the following code chunk, and see the visualization locally (http://localhost:8080/) without needed to build the data pipeline:

```
npm install
npm run serve
```

## Build the data behind the visualization and push to S3

This step is not needed to build the visualization locally since the data files are available through a public S3 bucket and can be accessed from `labs.waterdata.usgs.gov/visualizations/data/[FILENAME]`. Run this code if you need to update the data or base SVG behind the visualization.

### Generate the historic data

The historic data pipeline (`0_historic.yml`) is decoupled from the rest of the pipeline. It will build only when you run `scmake(remake_file = "0_historic.yml")`. Otherwise, the `1_fetch.yml` part of the pipeline will assume the historic data is on S3 ready to use and will download the data using the filepaths described in `0_config.yml`. The historic data is being stored on the developer VPC in the `vizlab-data` bucket but should be moved for public access later if we do a data release. 

### Generate the data behind the viz

If you plan to be able to push the final data to S3, you need to have the appropriate S3 configs prepared. The file `lib/cfg/s3_config_viz.yml` expects you to have credentials labeled `[prod]` in your `~/.aws/credentials` file (rather than `[default]`). Also note that any of the targets that call `scipiper::s3_put()` will require you to be on the USGS Network (VPN). If you want to build the data pipeline but don't need to (or can't) push to S3, you can run `options(scipiper.dry_put = TRUE)` and then the code listed below. This will skip the upload step.

Once your configurations are set up, run the following to generate the data needed by the visualization. 

```r
library(scipiper)
scmake()
```

In the end the following targets should have been built successfully (because they are what is pushed to S3 and used by the Vue code):

- `visualizations/data/gw-conditions-time-labels.csv.ind`
- `visualizations/data/gw-conditions-peaks-map.svg`
- `visualizations/data/gw-conditions-peaks-timeseries.csv.ind`
- `visualizations/data/gw-conditions-site-coords.csv.ind`
- `visualizations/data/gw-conditions-daily-proportions.csv.ind`

Follow the two steps below in order to retain a copy of the current visualization's timeseries data, so that we can access it in the future without a data pipeline rebuild. 

1. Authenticate to AWS using the Dev VPC. Use `saml2aws login` in your regular command line, and then make sure you choose the `gs-chs-wma-dev` account when prompted. If you are still authenticated to the Prod VPC, try running `saml2aws login --force` in order to force a new login.
1. Then run `scmake('3_visualize/out/gw-conditions-peaks-timeseries-s3copy.ind')` to push a copy of the `3_visualize/out/gw-conditions-peaks-timeseries.csv` file to the `vizlab-data` bucket on the Dev VPC. The file will be automatically given a new name based on the `viz_start_date` and `viz_end_date` target values, using this pattern: `gw-conditions/viz-previous-peak-data/gw-conditions-peaks-timeseries-[viz_start_date]_[viz_end_date].csv`.

## Disclaimer

This software is in the public domain because it contains materials that originally came from the U.S. Geological Survey, an agency of the United States Department of Interior. For more information, see the official USGS copyright policy at [http://www.usgs.gov/visual-id/credit_usgs.html#copyright](http://www.usgs.gov/visual-id/credit_usgs.html#copyright)

This information is preliminary or provisional and is subject to revision. It is being provided to meet the need for timely best science. The information has not received final approval by the U.S. Geological Survey (USGS) and is provided on the condition that neither the USGS nor the U.S. Government shall be held liable for any damages resulting from the authorized or unauthorized use of the information. Although this software program has been used by the USGS, no warranty, expressed or implied, is made by the USGS or the U.S. Government as to the accuracy and functioning of the program and related program material nor shall the fact of distribution constitute any such warranty, and no responsibility is assumed by the USGS in connection therewith.

This software is provided "AS IS."


[
  ![CC0](http://i.creativecommons.org/p/zero/1.0/88x31.png)
](http://creativecommons.org/publicdomain/zero/1.0/)
