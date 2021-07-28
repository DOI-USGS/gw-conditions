<template>
  <section>
      <div id="title-container">
      <h1>U.S. Groundwater Conditions</h1></div>
<div id="grid-container">
    <div id="map-container">
       <GWLmap id="map_gwl" class="map" />
    </div>
    <div id="legend-container" />
    </div>
  </section>
</template>
<script>
import * as d3Base from 'd3';
import GWLmap from "@/assets/anomaly_peaks.svg";
export default {
  name: "GWLsvg",
    components: {
      GWLmap
    },
    data() {
    return {
      publicPath: process.env.BASE_URL, // this is need for the data files in the public folder, this allows the application to find the files when on different deployment roots
      d3: null,
      quant_peaks: null,
      date_peaks: null,
      svg: null,
      peaky: null,
      site_coords: null,
      site_count: null,
      percData: null,

      peak_grp: null,
      day_length: 20, // frame duration in milliseconds

    }
  },
  mounted(){

      this.d3 = Object.assign(d3Base);
      this.loadData();   

      this.svg = this.d3.select("svg.map")

      // define style before page fully loads
      this.svg.selectAll(".map-bkgrd")
        .style("stroke", "black")
        .style("stroke-width", "1px")
        .style("fill", "white")

    },
    methods:{
       loadData() {
        const self = this;
        // read in data 
        let promises = [
        self.d3.csv(self.publicPath + "quant_peaks.csv",  this.d3.autotype), // used to draw legend shapes
        self.d3.csv(self.publicPath + "date_peaks.csv",  this.d3.autotype),
        self.d3.csv(self.publicPath + "gw_sites.csv",  this.d3.autotype),
        self.d3.csv(self.publicPath + "gwl_daily_count.csv",  this.d3.autotype),
        self.d3.json(self.publicPath + "perc_df.json",  this.d3.autotype)
        ];
        Promise.all(promises).then(self.callback); // once it's loaded
      },
      callback(data) {
        // assign data
        this.quant_peaks = data[0]; // peak shapes for legend
        this.date_peaks = data[1]; // gwl timeseries data
        this.site_coords = data[2]; // site positioning on svg
        this.site_count = data[3]; // number of sites x quant_category x wyday
        var jtest = data[3];
       // let jtest = this.d3.json(self.publicPath + "perc_df.json");
        // console.log(jtest)


        // water days
        var wyday = this.date_peaks.columns
        wyday.shift();

        // sites
        var sites_list = this.site_coords.map(function(d)  { return d.site_no })
        var n = sites_list.length // to create nested array for indexing in animation

        // site placement on map
        this.sites_x = this.site_coords.map(function(d) { return d.x })
        this.sites_y = this.site_coords.map(function(d) { return d.y })

        // reorganize - site is the key with gwl for each day of the wy
        // can be indexed using site key (gwl_#) - and used to bind data to DOM elements
         this.peaky = [];
          for (i = 1; i < n; i++) {
              var key = sites_list[i];
              var wyday = this.date_peaks.map(function(d){  return d['wyday']; });
              var gwl = this.date_peaks.map(function(d){  return d[key]; });
              var site_x = this.sites_x[i];
              var site_y = this.sites_y[i];
              this.peaky.push({key: key, wyday: wyday, gwl: gwl, site_x: site_x, site_y: site_y})
          };

       // set color scale for path fill
        this.quant_color = this.d3.scaleThreshold()
        .domain([-40, -25, 25, 40])
        .range(["#1A3399","#479BC5","#669957","#C1A53A","#7E1900"]) // using a slightly darker green

        //same for bar chart data
        var quant_cat = [...new Set(this.quant_peaks.map(function(d) { return d.quant}))];
        var n_quant = quant_cat.length
        var perc = this.site_count.map(function(d){  return d[quant_cat[0]]; });
        this.percData = [];
          for (i = 0; i < n_quant; i++) {
           var key_quant = quant_cat[i];
          var wyday = this.site_count.map(function(d){ return d['wyday']});
          var perc = this.site_count.map(function(d){ return d[key_quant]});
          this.percData.push({key_quant: key_quant, wyday: wyday, perc: perc})
          };
      console.log(this.percData)

       // draw the chart
        this.makeLegend();
        this.drawFrame1(this.peaky);

      // animated bar chart
        //this.legendBarChart(this.percData);

      },
      makeLegend(){

        var legend_height = 300;
        var legend_width = 500;

        // make a legend 
          var legend_peak = this.d3.select("#legend-container")
          .append("svg")
          .attr("width", legend_width)
          .attr("height", legend_height)
          .attr("id", "map-legend")
          .append("g").classed("legend", true)

          var legend_keys = ["Very low", "low", "Normal", "High","Very high"];
          var shape_dist = [5,25,42,42,60,83,103];

        // draw path shapes
        legend_peak.selectAll("peak_symbol")
          .data(this.quant_peaks)
          .enter()
          .append("path")
            .attr("fill", function(d){return d["color"]})
            .attr("d", function(d){return d["path_quant"]})
            .attr("transform", function(d, i){return "translate(250, " + (legend_height/2-shape_dist[i]) + ") scale(.8)"})
            .attr("id", function(d){return d["quant"]})
            .attr("class", "peak_symbol")

        // add categorical labels very low - very high
        legend_peak.selectAll("mylabels")
          .data(legend_keys)
          .enter()
          .append("text")
            .attr("x", 270)
            .attr("y", function(d,i){ return legend_height/2 - (i*22)}) // 100 is where the first dot appears. 25 is the distance between dots
            .text(function(d){ return d})
            .attr("text-anchor", "left")
            .style("alignment-baseline", "middle")

      },
      drawFrame1(data){         
        const self = this;

          // select existing paths using class
          // was dropping positioning because svg-loader and svgo are cleaning out <g>s?
          var start = 0;
            this.peak_grp = this.svg.selectAll("path.peak")
              .data(data, function(d) { return d ? d.key : this.class; }) // binds data based on class/key
              .join("path") // match with selection
              .attr("transform", d => `translate(` + d.site_x + ' ' + d.site_y + `) scale(0.35 0.35)`)

            // draws a oath for each site, using the first date
            this.peak_grp 
             .attr("class", function(d) { return d.key })
             .attr("fill", function(d) { return self.quant_color(d.gwl[0]) }) // this is not exactly right
             .attr("stroke-width", "1px")
             .attr("opacity", ".5")
             .attr("d", function(d) { return "M-10 0 C -10 0 0 " + d.gwl[start] + " 10 0 Z" } ) // d.gwl.# corresponds to day of wy, starting with 0

          this.animateGWL(start); // once sites are drawn, trigger animation
          this.legendBarChart(this.percData, start);
      },
      animateGWL(start){
         const self = this;
        // animate path d and fill by wy day    
        if (start < 364){
      // transition through days in sequence
        this.peak_grp
        .transition()
        .duration(this.day_length)  // duration of each day
        .attr("d", function(d) { return "M-10 0 C -10 0 0 " + d.gwl[start] + " 10 0 Z" })
        .attr("fill", function(d) { return self.quant_color(d.gwl[start]) }) // this is not exactly right
        .end()
        .then(() => this.animateGWL(start+1)) // loop animation increasing by 1 wyday
        // TODO: check why there are 367 days

        } else {
      // if it's the last day of the water year, stop animation 
       this.peak_grp
          .transition()
          .duration(this.day_length)  // duration of each day
          .attr("d", function(d) { return "M-10 0 C -10 0 0 " + d.gwl[364] + " 10 0 Z" })
        }

      },
      legendBarChart(data, start){
        // bar chart showing proportion of gages in each category

        // scales
        var w = 225;
        var h = 110;

        var xScale = this.d3.scaleLinear()
        .domain([0,0.55])
        .range([0, w])

        var yScale = this.d3.scaleBand()
        .domain(["Veryhigh", "High", "Normal", "Low", "Verylow"])
        .range([h, 0])

        // add bar chart
        var svg = this.d3.select("#map-legend")
        .append("g")
        .classed("bar-chart", true)

        svg.selectAll("rect")
          .data(data)
          .enter()
          .append("rect")
          .classed("bars", true)
          .attr("width", function(d) {
            return xScale(d.perc[start]);
          })
          .attr("y", function(d, i) {
            return 145 - yScale(d.key_quant)
          })
          .attr("x", function(d) {
            return w - xScale(d.perc[start])
          })
          .attr("id", function(d){ return d.key_quant})
          .attr("height", "10")
          .attr("fill", "royalblue")

          this.animateBarChart(start);
          

      },
      animateBarChart(start){

         var xScale = this.d3.scaleLinear()
        .domain([0,0.55])
        .range([0, 225])

 if (start < 364){
        this.d3.selectAll(".bars")
        .transition()
        .duration(this.day_length) 
        .attr("x", function(d) {
            return 225 - xScale(d.perc[start])
          })
          .attr("width", function(d) {
            return xScale(d.perc[start]);
          })
        .end()
        .then(() => this.animateBarChart(start+1))
  } else {
    this.d3.selectAll(".bars")
        .transition()
        .duration(this.day_length) 
        .attr("x", function(d) {
            return 225 - xScale(d.perc[364])
          })
          .attr("width", function(d) {
            return xScale(d.perc[364]);
          })

  }
      }
    }
}
</script>
<style scoped lang="scss">
#map-container{
  width: auto;
  //height: 85vh;
  margin: 2%;
  margin-bottom: 0;
  position: relative;
  grid-area: map;

    .map {
    position: relative;
    left:0;
    top: 0;
    width: 100%;
    height: auto;
  }
}
// each piece is a separate div that can be positioned or overlapped with grid
#grid-container {
  display: grid;
  grid-template-columns: 20% 1fr 20%;
  grid-template-rows: 2fr 1fr;
  grid-template-areas:
  "map map map"
  "legend legend legend"
}
#legend-container {
  
}

#title-container {
  //width: 100vw;
  height: auto;
  background-color: #0d5fca;
  grid-area: title;
  h1 {
    width: 95vw;
    color:white;
    height: auto;
    padding: 10px;
    padding-left: 15px;
    
  }
}

</style>