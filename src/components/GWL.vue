<template>
  <section>
    <div id="title-container">
      <h1>U.S. Groundwater conditions</h1></div>
    <div id="map-container">
       <SampleSvg class="map" />
    </div>
  </section>
</template>
<script>
import * as d3Base from 'd3';
import SampleSvg from "@/assets/anomaly_peaks 3.svg";
export default {
  name: "GWLsvg",
    components: {
      SampleSvg
    },
    data() {
    return {

    }
  },
  mounted(){

      this.d3 = Object.assign(d3Base);
      this.colorStroke();
      
    },
    methods:{
      colorStroke(){

        this.d3.selectAll(".map-bkgrd") // map outline
          .attr("fill", "transparent")
          .attr("stroke", "black")
          .attr("stroke-width", "1px")
          .transition()
          .duration(2000)
          .attr("stroke", "pink")
          .transition()
          .duration(2000)
          .attr("stroke", "purple")
          .transition()
          .duration(2000)
          .attr("stroke", "blue")
          .transition()
          .duration(2000)
          .attr("stroke", "green")
          .on("end", this.rainbowStrobe);

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
  background-color: #c2c4c5;
  h1 {
    width: 95vw;
    height: auto;
    padding: 15px;
    
  }
}

</style>