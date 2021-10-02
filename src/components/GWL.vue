<template>
  <section>
    <div id="grid-container">
      <div id="title-container">
        <h2
          id="title-main"
          class="title"
        >
          U.S. Groundwater Conditions
        </h2>
        <h3
          id="title-sub"
          class="title"
        >
          The low down on flow down low
        </h3>
      </div>
      <div id="map-container">
        <GWLmap
          id="map_gwl"
          class="map"
        />
      </div>
      <div id="legend-container" />
      <div id="line-container" />
      <div id="text-container">
        <p>
          Seitan 8-bit in, veniam pickled pitchfork hammock sustainable aliqua edison bulb. Four dollar toast man bun affogato crucifix locavore ut, labore quinoa gastropub qui reprehenderit adipisicing chicharrones asymmetrical. Live-edge squid banjo bespoke prism migas post-ironic tousled kitsch aute banh mi veniam ut kogi. Literally woke sriracha taxidermy freegan +1 voluptate church-key tempor cornhole humblebrag small batch fanny pack. 
        </p>
      </div>
    </div>
  </section>
</template>
<script>
import * as d3Base from 'd3';
import GWLmap from "@/assets/anomaly_peaks.svg";
import { TimelineMax } from "gsap/all"; 

export default {
  name: "GWLsvg",
    components: {
      GWLmap
    },
    data() {
    return {
      publicPath: process.env.BASE_URL, // this is need for the data files in the public folder, this allows the application to find the files when on different deployment roots
      d3: null,

      // dimensions
      width: null,
      height: null,
      margin: { top: 50, right: 0, bottom: 50, left: 0 },
      mar: 20,

      // data mgmt
      quant_peaks: null,
      date_peaks: null,
      svg: null,
      peaky: null,
      site_coords: null,
      site_count: null,
      percData: null,
      days: null,

      peak_grp: null,
      day_length: 1, // frame duration in milliseconds
      current_time: 0,
      start: 0,
      n_days: 365,
      sites_list: null,
      //t2: null,

      // style for timeline
      button_color: "grey",
      button_hilite: "black",

      // sclaes
      xScale: null,
      yScale: null,

      // roma color scale
   /*    verylow: "#7E1900",
      low: "#C1A53A",
      normal: "#8fce83",
      high: "#479BC5",
      veryhigh: "#1A3399", */
      pal_roma: null,
      pal_roma_rev: null,

      // color scale alternatives
/*       // Green-Brown
      verylow: "#a6611a",
      low: "#dfc27d",
      normal: "#f5f5f5",
      high: "#80cdc1",
      veryhigh: "#018571", */

     // Blue-Brown
      verylow: "#BF6200",
      low: "#FEB100",
      normal: "#B3B3B3",
      high: "#2E9EC6",
      veryhigh: "#28648A",



       // TODO: derive from pipeline. inputs are months, day sequence nested w/ key
      // timeline data
      months: [
        { 'name': 'Jan', 'day': '1' },
        { 'name': 'Feb', 'day': '31' },
        { 'name': 'Mar', 'day': '60' },
        { 'name': 'Apr', 'day': '90' },
        { 'name': 'May', 'day': '120' },
        { 'name': 'Jun', 'day': '150' },
        { 'name': 'Jul', 'day': '181' },
        { 'name': 'Aug', 'day': '210' },
        { 'name': 'Sept', 'day': '240' },
        { 'name': 'Oct', 'day': '270' },
        { 'name': 'Nov', 'day': '300' },
        { 'name': 'Dec', 'day': '331' },
        { 'name': 'Jan', 'day': '367' }
      ],

    }
  },
  mounted(){
      this.d3 = Object.assign(d3Base);

      // resize
      this.width = window.innerWidth - this.margin.left - this.margin.right;
      this.height = window.innerHeight*.5 - this.margin.top - this.margin.bottom;

      this.pal_roma = [this.verylow, this.low, this.normal, this.high, this.veryhigh];
      this.pal_roma_rev = [this.veryhigh, this.high, this.normal, this.low, this.verylow];
      
      // read in data
      this.loadData();   
      this.setScales();

      // define style before page fully loads
      this.svg = this.d3.select("svg.map")

       this.svg.selectAll(".map-bkgrd")
        .style("stroke", "white")
        .style("stroke-width", "0.1px")
        .style("fill", "white")

    },
    methods:{
       loadData() {
        const self = this;
        // read in data 
        let promises = [
        self.d3.csv(self.publicPath + "quant_peaks.csv",  this.d3.autotype), // used to draw legend shapes - color palette needs to be pulled out
        self.d3.csv("https://labs.waterdata.usgs.gov/visualizations/data/gw-conditions-wy20.csv",  this.d3.autotype),
        self.d3.csv("https://labs.waterdata.usgs.gov/visualizations/data/gw-conditions-sites.csv",  this.d3.autotype), 
        self.d3.csv("https://labs.waterdata.usgs.gov/visualizations/data/gw-conditions-daily-count.csv",  this.d3.autotype)
        ];
        Promise.all(promises).then(self.callback); // once it's loaded
      },
      callback(data) {
        // assign data
        this.quant_peaks = data[0]; // peak shapes for legend
        this.date_peaks = data[1]; // gwl timeseries data
        this.site_coords = data[2]; // site positioning on svg - not needed with svg fix?
        this.site_count = data[3]; // number of sites x quant_category x wyday

        // water days
        var wyday = this.date_peaks.columns
        wyday.shift();

        // sites
        this.sites_list = this.site_coords.map(function(d)  { return d.site_no })
        var n = this.sites_list.length // to create nested array for indexing in animation

        // site placement on map
        this.sites_x = this.site_coords.map(function(d) { return d.x })
        this.sites_y = this.site_coords.map(function(d) { return d.y })

        // reorganize - site is the key with gwl for each day of the wy
        // can be indexed using site key (gwl_#) - and used to bind data to DOM elements
         this.peaky = [];
          for (i = 1; i < n; i++) {
              var key = this.sites_list[i];
              var wyday = this.date_peaks.map(function(d){  return d['wyday']; });
              var gwl = this.date_peaks.map(function(d){  return d[key]; });
              var site_x = this.sites_x[i];
              var site_y = this.sites_y[i];
              this.peaky.push({key: key, wyday: wyday, gwl: gwl, site_x: site_x, site_y: site_y})
          };

       // set color scale for path fill
        this.quant_color = this.d3.scaleThreshold()
        .domain([-40, -25, 25, 40])
        .range(this.pal_roma_rev) 

        //same for bar chart data
        var quant_cat = [...new Set(this.quant_peaks.map(function(d) { return d.quant}))];
        var n_quant = quant_cat.length
        this.percData = [];
          for (i = 0; i < n_quant; i++) {
          var key_quant = quant_cat[i];
          var wyday = this.site_count.map(function(d){ return d['wyday']});
          var perc = this.site_count.map(function(d){ return d[key_quant]});
          this.percData.push({key_quant: key_quant, wyday: wyday, perc: perc})
          };

      this.days = this.site_count.map(function(d) { return  d['wyday']})

       // draw the chart
        this.makeLegend();
        this.drawFrame1(this.peaky);

      // animated time chart
        this.drawLine(this.days, this.percData)

      },
      createPanel(month) {
        var tl = new TimelineMax();
        tl.to("tl_" + month)
        // add rest of this
        return tl;
      },
      drawLine(date_range, prop_data) {
        const self = this;

        var line_height = 250;

      // set up svg for timeline
      var svg = this.d3.select("#line-container")
        .append("svg")
        .attr("width", "100%")
        .attr("preserveAspectRatio", "xMinYMin meet")
        .attr("viewBox", "0 0 " + this.width + " " + line_height)
        .attr("id", "x-line")

      // define axes
      var xLine = this.d3.axisBottom()
        .scale(this.xScale)
        .ticks(0).tickSize(0);

      // draw axes
      var liney = svg.append("g")
        .call(xLine)
        .attr("transform", "translate(0," + 120 + ")")
        .classed("liney", true)

      // style axes
      liney.select("path.domain")
        .attr("id", "timeline-x")
        .attr("color", "lightgrey")
        .attr("stroke-width", "3px")

    // timeline events/"buttons"
      var button_month = svg.append("g")
      .classed("#btn-month", true)
      .attr("transform", "translate(0," + 120 + ")")
      .attr("z-index", 100)

    // month points on timeline
    // TODO: make functions that accept any date and label for annotations
      button_month.selectAll(".button_inner")
      .data(this.months).enter()
      .append("circle")
      .attr("class", function(d,i) { return "button_inner inner_" + d.name + " " + d.name } ) 
      .attr("r", 3)
      .attr("cx", function(d) { return self.xScale(d.day) })
      .attr("cy", 0)
      .attr("stroke", this.button_color)
      .attr("stroke-width", "2px")
      .attr("fill", this.button_color)
      .on('click', function(d, i) {
        //self.moveTimeline(d); // requires gsap for playback control or some way to cancel playback loop partway
      })
      .on('mouseover', function(d, i) {
        self.buttonSelect(d);
      })
      .on('mouseout', function(d, i) {
        self.buttonDeSelect(d);
      })

      // month labels
      button_month.selectAll(".button_name")
      .data(this.months)
      .enter()
      .append("text")
      .attr("class", function(d,i) { return "button_name name_" + d.name + " " + d.name } ) 
      .attr("x", function(d) { return self.xScale(d.day)-12 }) // centering on pt
      .attr("y", 25)
      .attr("stroke", this.button_color)
      .text(function(d, i) { return d.name })
      .attr("text-align", "middle")
      .on('click', function(d, i) {
        //self.moveTimeline(d);
      })
      .on('mouseover', function(d, i) {
        self.buttonSelect(d);
      })
      .on('mouseout', function(d, i) {
        self.buttonDeSelect(d);
      })

      // year annotations
      // TODO: derive from data input via pipeline
      button_month
      .append("text")
      .attr("class", function(d,i) { return "button_year" } ) 
      .attr("x", function(d) { return self.xScale(1)-10 }) // centering on pt
      .attr("y", 45)
      .attr("stroke", this.button_color)
      .text(function(d, i) { return 2021 })

      button_month
      .append("text")
      .attr("class", function(d,i) { return "button_year" } ) 
      .attr("x", function(d) { return self.xScale(367)-20 }) // centering on pt
      .attr("y", 45)
      .attr("stroke", this.button_color)
      .text(function(d, i) { return 2022 })

      button_month
      .append("text")
      .attr("class", function(d,i) { return "axis_label" } ) 
      .attr("x", function(d) { return self.xScale(1)-10 }) // centering on pt
      .attr("y", -110)
      .attr("stroke", this.button_color)
      .text(function(d, i) { return "Proportion of wells" })

      // add line chart
       // line chart showing proportion of gages in each category
         var line_chart = svg.append("g")
          .classed("time-chart", true)
          .attr("id", "time-legend")
          .attr("transform", "translate(0," + 20 + ")")

        var bar_color = this.d3.scaleOrdinal()
        .domain(["Veryhigh", "High", "Normal", "Low","Verylow"])
        .range(this.pal_roma_rev)

        var line = this.d3.line()
          .defined(d => !isNaN(d))
          .x((d, i) => self.xScale(this.days[i]))
          .y(d => self.yScale(d))

        // add line chart
        line_chart.append("g")
            .attr("fill", "none")
            .attr("stroke-linejoin", "round")
            .attr("stroke-linecap", "round")
          .selectAll("path")
          .data(prop_data)
          .join("path")
          .attr("d", d => line(d.perc))
          .attr("stroke", function(d) { return bar_color(d.key_quant) })
          .attr("stroke-width", "3px")
          .attr("opacity", 0.7);

      // animate line to time
      var start = this.start;

       line_chart.append("rect")
          .data(this.days)
          .classed("hilite", true)
          .attr("width", "5")
          .attr("height", "100")
          .attr("opacity", 0.5)
          .attr("fill", "grey")
          .attr("x", self.xScale(this.days[start]))
         
        this.animateLine(start);

      },
      setScales(){

        this.xScale = this.d3.scaleLinear()
        .domain([0, this.n_days])
        .range([this.mar, this.width-2*this.mar])

        this.yScale = this.d3.scaleLinear()
        .domain([0, 0.6])
        .range([100, 0])

      },
      animateLine(start){
        // animates grey line on timeseries chart to represent current timepoint
        const self = this;
        var line_height = 250;

        if (start < this.n_days){
          this.d3.selectAll(".hilite")
          .transition()
            .duration(this.day_length) 
            .attr("x", self.xScale(this.days[start]))
          .end()
          .then(() => this.animateLine(start+1))
        } else {
          this.d3.selectAll(".hilite")
            .transition()
            .duration(this.day_length) 
            .attr("x", x(this.days[this.n_days]))
        }
      },
      buttonSelect(d){
        // highlight on timeline when hovered
        this.d3.selectAll("." + d.name)
        .transition()
        .duration(100)
        .attr("stroke", this.button_hilite)

        this.d3.selectAll(".inner_" + d.name )
        .transition()
        .duration(100)
        .attr("r", 6)
        .attr("fill", this.button_hilite)
        .attr("stroke", this.button_hilite)
      },
      buttonDeSelect(d){
        // unhighlight on mouseout
        this.d3.selectAll(".button_name")
        .transition()
        .duration(100)
        .attr("stroke", this.button_color)
        .attr("fill", this.button_color)

      this.d3.selectAll(".button_inner")
        .transition()
        .duration(100)
        .attr("stroke", this.button_color)
        .attr("fill", this.button_color)

        this.d3.selectAll(".inner_" + d.name )
        .transition()
        .duration(100)
        .attr("r", 3)
        .attr("fill", this.button_color)
        .attr("stroke", this.button_color)
      },
      initTime(){
        // TO DO: init nested timelines for playback control
        // broken up by month and tagged for user control
        var tl_jan = new TimelineMax(); // TimelineMax permits repeating animation
        var tl_feb = new TimelineMax();
        var tl_mar = new TimelineMax();
        var tl_apr = new TimelineMax();
        var tl_may = new TimelineMax();
        var tl_jun = new TimelineMax();
        var tl_jul = new TimelineMax();
        var tl_aug = new TimelineMax();
        var tl_sep = new TimelineMax()
        var tl_oct = new TimelineMax()
        var tl_nov = new TimelineMax()
        var tl_dec = new TimelineMax()

        // add to parent timeline
        // this timeline is used to set timing, duration, speed, stop/start, and keep everythign synchronized
        var master = new TimelineMax();
        master.add(tl_jan)
        .add(tl_feb)
        .add(tl_mar)
        .add(tl_apr)
        .add(tl_may)
        .add(tl_jun)
        .add(tl_jul)
        .add(tl_aug)
        .add(tl_sep)
        .add(tl_oct)
        .add(tl_nov)
        .add(tl_dec) 

      },
      makeLegend(){

        var legend_height = 160;
        var legend_width = 240;

        // make a legend 
        var legend_peak = this.d3.select("#legend-container")
          .append("svg")
          .attr("width", legend_width)
          .attr("height", legend_height)
          .attr("id", "map-legend") 
          .attr("preserveAspectRatio", "xMinYMin meet")
          .attr("viewbox", "0 0 " + legend_width + " " + legend_height)
          .append("g").classed("legend", true)
          .attr("transform", "translate(90, 0)")
                  
        var legend_keys = ["Very low", "Low", "Normal", "High","Very high"]; // labels
        var legend_color = [this.verylow, this.low, this.normal,this.normal, this.high, this.veryhigh];
        var shape_dist = [5,25,42,42,60,83,103]; // y positioning (normal has 2 shapes butted together)
        var perc_label = ["0 - 0.1", "0.1 - 0.25" ,"0.25 - 0.75", "0.75 - 0.9", "0.9 +"]

        // draw path shapes and labels
        legend_peak
          .append("text")
          .text("GWL")
          .attr("x", -20)
          .attr("y", "30")
          .style("font-size", "20")
          .style("font-weight", 700)
          .attr("text-anchor", "end")

        legend_peak
          .append("text")
          .text("Percentile")
          .attr("x", 105)
          .attr("y", "30")
          .style("font-size", "20")
          .style("font-weight", 700)
          .attr("text-anchor", "end")
        
        legend_peak.selectAll("peak_symbol")
          .data(this.quant_peaks)
          .enter()
          .append("path")
            .attr("fill", function(d, i){return legend_color[i]})
            .attr("d", function(d){return d["path_quant"]})
            .attr("transform", function(d, i){return "translate(0, " + (140-shape_dist[i]) + ") scale(.8)"})
            .attr("id", function(d){return d["quant"]})
            .attr("class", "peak_symbol")

        // add categorical labels very low - very high
        legend_peak.selectAll("mylabels")
          .data(legend_keys)
          .enter()
          .append("text")
            .attr("x", -20)
            .attr("y", function(d,i){ return 140 - (i*22)}) // 100 is where the first dot appears. 25 is the distance between dots
            .text(function(d){ return d})
            .attr("text-anchor", "end")
            .style("alignment-baseline", "middle")

         legend_peak.selectAll("percLabels")
          .data(perc_label)
          .enter()
          .append("text")
            .attr("x", 20)
            .attr("y", function(d,i){ return 140 - (i*22)}) // 100 is where the first dot appears. 25 is the distance between dots
            .text(function(d){ return d})
            .attr("text-anchor", "start")
            .style("alignment-baseline", "middle")

      },
      drawFrame1(data){         
        // draw the first frame of the animation
        const self = this;

          // select existing paths using class
          var start = this.start;
            this.peak_grp = this.svg.selectAll("path.gwl_glyph")
              .data(data, function(d) { return d ? d.key : this.class; }) // binds data based on class/key
              .join("path") // match with selection
              .attr("transform", d => `translate(` + d.site_x + ' ' + d.site_y + `) scale(0.35 0.35)`)

            // draws a path for each site, using the first date
            this.peak_grp 
             .attr("class", function(d) { return d.key })
             .attr("fill", function(d) { return self.quant_color(d.gwl[0]) }) 
             .attr("opacity", ".5")
             .attr("d", function(d) { return "M-10 0 C -10 0 0 " + d.gwl[start] + " 10 0 Z" } ) // d.gwl.# corresponds to day of wy, starting with 0

          this.animateGWL(start); // once sites are drawn, trigger animation
      },
      animateGWL(start){
         const self = this;
      // animate path d and fill by wy day    

        if (start < 365 ){
      // transition through days in sequence
        this.peak_grp
        .transition()
        .duration(this.day_length)  // duration of each day
        .attr("d", function(d) { return "M-10 0 C -10 0 0 " + d.gwl[start] + " 10 0 Z" })
        .attr("fill", function(d) { return self.quant_color(d.gwl[start]) })
        .end()
        .then(() => this.animateGWL(start+1)) // loop animation increasing by 1 wyday

        } else {
      // if it's the last day of the water year, stop animation 
       this.peak_grp
          .transition()
          .duration(this.day_length)  // duration of each day
          .attr("d", function(d) { return "M-10 0 C -10 0 0 " + d.gwl[365] + " 10 0 Z" })
          .attr("fill", function(d) { return self.quant_color(d.gwl[365]) })
        }
      }
    }
}
</script>
<style scoped lang="scss">

// each piece is a separate div that can be positioned or overlapped with grid
// mobile first
#grid-container {
  display: grid;
  padding-right: 2rem;
  width: 100%;
  vertical-align: middle;
  overflow: hidden;
  grid-template-areas:
  "title title"
  "text legend"
  "map map"
  "line line"
}
#map-container{
  grid-area: map;
  padding: 1rem;
  padding-right: 2rem;
}
#text-container {
  grid-area: text;
  padding:20px;
  padding-top: 0px;
  padding-right: 2rem;
  // controlling positioning within div as page scales
  display: flex;
  justify-content: center;
  align-items: top;
}
#line-container {
  grid-area: line;
  margin-bottom: 10px;
}
#legend-container {
  grid-area: legend;
  display: flex;
  justify-content: flex-end;
  align-items: flex-start;
}
#title-container {
  padding:20px;
  padding-bottom: 0px;
  height: auto;
  grid-area: title;
  h1, h2, h3 {
    width: 95vw;
    color:"black";
    height: auto;
    padding: 4px;
  }
}

// drop shadow on map outline
#bkgrd-map-grp {
  filter: drop-shadow(0.2rem 0.2rem 0.5rem rgba(38, 49, 43, 0.15));
  stroke-width: 0.2;
  color: "white"
}
// annotated timeline
.liney {
  stroke-width: 2px;
  color: rgb(143, 206, 131);
}

// desktop
@media (min-width:1024px) {
  #grid-container {
    grid-template-columns: 3fr 1fr;
    grid-template-areas:
    "title title"
    "map legend"
    "map text"
    "map text"
    "line line"
  }
  .title {
  text-align: right;
  }
  #legend-container {
    display: flex;
    justify-content: center;
    align-items: center;
  }
  #line-container {
  grid-area: line;
  margin-bottom: 10px;
  margin-left: 10px;
}
}
// glyph paths
.gwl_glyph {
  stroke: none; 
  fill-opacity: 50%;
  //transform: scale(0.35, 0.35);
}

</style>