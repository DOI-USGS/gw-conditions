<template>
  <section>
    <div id="title-container">
      <h1>U.S. Groundwater conditions</h1></div>
    <div>

</div>
    <div id="map-container">
       <GWLmap class="map" />
    </div>
  </section>
</template>
<script>
import * as d3Base from 'd3';
import GWLmap from "@/assets/anomaly_peaks_20201031_20201031.svg";
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

    }
  },
  mounted(){

      this.d3 = Object.assign(d3Base);
      this.colorStroke();
      this.loadData();      
    },
    methods:{
       loadData() {
        const self = this;
        // read in data 
        let promises = [self.d3.csv(self.publicPath + "svg_files.csv",  this.d3.autotype),
        self.d3.csv(self.publicPath + "quant_peaks.csv",  this.d3.autotype),
        self.d3.csv(self.publicPath + "date_peaks.csv",  this.d3.autotype)];
        Promise.all(promises).then(self.callback); 
      },
      callback(data) {
        var svg_files = data[0];
        this.quant_peaks = data[1];
        this.date_peaks = data[2];

        this.makePeaks();
      },
      makePeaks(){
        var svg = this.d3.select("svg")
        var peak_defs = svg.append('defs').append('g').attr("id","peaks")

        // add defs for peak categories and <use> with attrTweeb
        peak_defs.selectAll("path").data(this.quant_peaks).enter()
          .append("path")
          .attr("fill", function(d){return d["color"]})
          .attr("d", function(d){return d["path_quant"]})
          .attr("id", function(d){return d["quant"]})

          // test how to draw using <use>
          svg.append("g").attr("transform","translate(250,200) scale(2,2)")
		        .append("use").attr("xlink:href","#High").attr("class","peak")

          // for every site, draw a peak for the first day of the time period
          // requires input data with site, site coords in svg, date, and quant_category

      },
      colorStroke(){

        this.d3.selectAll(".map-bkgrd") // map outline
          .attr("fill", "transparent")
          .attr("stroke", "black")
          .attr("stroke-width", "1px")
          

      },
      rainbowStrobe(){
        this.d3.selectAll(".map")
          .transition()
          .duration(2000)
          .attr("stroke", "yellow")
          .transition()
          .duration(2000)
          .attr("stroke", "red")
          .transition()
          .duration(2000)
          .attr("stroke", "orange")
          .transition()
          .duration(2000)
          .attr("stroke", "orchid")
          .on("end", this.colorStroke);
      }
    }
}
</script>
<style scoped lang="scss">
#map-container{
  width:90vw;
  height: auto;
  margin: 5%;
}
#title-container {
  width: 100vw;
  height: auto;
  background-color: #0d5fca;
  h1 {
    width: 95vw;
    color:white;
    height: auto;
    padding: 15px;
    
  }
}

</style>