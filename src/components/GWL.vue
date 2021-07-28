<template>
  <section>
    <div id="title-container">
      <h1>U.S. Groundwater Conditions</h1></div>
    <div>

</div>
    <div id="map-container">
       <GWLmap class="map" />
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
      svg_files: null,
      svg: null,
      peaky: null,
      site_coords: null,
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
        self.d3.csv(self.publicPath + "gw_sites.csv",  this.d3.autotype)
        ];
        Promise.all(promises).then(self.callback); // once it's loaded
      },
      callback(data) {
        // assign data
        this.quant_peaks = data[0]; // peak shapes for legend
        this.date_peaks = data[1]; // gwl timeseries data
        this.site_coords = data[2]; // site positioning on svg

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

        // draw the chart
        this.makeLegend();
        this.drawFrame1(this.peaky);
      },
      makeLegend(){

        // make a legend
          var legend_peak = this.svg.append("g").classed("legend", true)
          var legend_keys = ["Very high", "High", "Normal", "Low", "Very low"];
          var shape_dist = [5,25,42,43,60,83,103];

        // draw path shapes
        legend_peak.selectAll("peak_symbol")
          .data(this.quant_peaks)
          .enter()
          .append("path")
            .attr("fill", function(d){return d["color"]})
            .attr("d", function(d){return d["path_quant"]})
            .attr("transform", function(d, i){return "translate(50, " + (580-shape_dist[i]) + ") scale(.8)"})
            .attr("id", function(d){return d["quant"]})
            .attr("class", "peak_symbol")
            .attr("x", 50)
            //.attr("y", function(d,i){ return 500 + i*20}) // 100 is where the first dot appears. 25 is the distance between dots
            
        // add categorical labels very low - very high
        legend_peak.selectAll("mylabels")
          .data(legend_keys)
          .enter()
          .append("text")
            .attr("x", 70)
            .attr("y", function(d,i){ return 493 + i*23}) // 100 is where the first dot appears. 25 is the distance between dots
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

      }
    }
}
</script>
<style scoped lang="scss">
#map-container{
  width: auto;
  height: 85vh;
  margin: 2%;
  margin-bottom: 0;
  position: relative;

  .map {
    position: relative;
    left:0;
    top: 0;
    width: 100%;
    height: 100%;
  }
}
#title-container {
  width: 100vw;
  height: auto;
  background-color: #0d5fca;
  h1 {
    width: 95vw;
    color:white;
    height: auto;
    padding: 10px;
    padding-left: 15px;
    
  }
}

</style>