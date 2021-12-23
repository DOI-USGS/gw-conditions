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
      <!-- <div id="text-container">
        <p>
          Four dollar toast man bun affogato crucifix locavore ut, labore quinoa gastropub qui reprehenderit adipisicing chicharrones asymmetrical. Live-edge squid banjo bespoke prism migas post-ironic tousled kitsch aute banh mi veniam ut kogi. Literally woke sriracha taxidermy freegan +1 voluptate church-key tempor cornhole humblebrag small batch fanny pack. 
        </p>
      </div> -->
      <div id="play-container" />
    </div>
  </section>
</template>
<script>
import * as d3 from 'd3';
import GWLmap from "@/assets/gw-conditions-peaks-map.svg";
// modules: d3-scale, d3-selection, d3-transition, d3-path, d3-axis,

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
      mar: 50,

      // data mgmt
      quant_peaks: null,
      date_peaks: null,
      svg: null,
      percData: null,
      days: null,
      quant_path_gylph: null,

      peak_grp: null,
      day_length: 1, // frame duration in milliseconds
      current_time: 0,
      start: 0,
      n_days: null,
      sites_list: null,
      //t2: null,
      isPlaying: null,

      // style for timeline
      button_color: "grey",
      button_hilite: "black",

      // scales
      dates: null,
      xScale: null,
      yScale: null,
      line: null,
      //gwl_color: null,

     // Blue-Brown
      verylow: "#BF6200",
      low: "#FEB100",
      normal: "#B3B3B3",
      high: "#2E9EC6",
      veryhigh: "#28648A",
      pal_BuBr: null,

    }
  },
  mounted(){
      this.d3 = Object.assign(d3);

      // resize
      this.width = window.innerWidth - this.margin.left - this.margin.right;
      this.height = window.innerHeight*.5 - this.margin.top - this.margin.bottom;
      this.pal_BuBr = [this.veryhigh, this.high, this.normal, this.low, this.verylow];
      
      // read in data
      this.loadData();   

    },
    methods:{
       loadData() {
        const self = this;
        // read in data 
        let promises = [
        self.d3.csv(self.publicPath + "quant_peaks.csv",  this.d3.autotype), // used to draw legend shapes - color palette needs to be pulled out
        self.d3.csv("https://labs.waterdata.usgs.gov/visualizations/data/gw-conditions-wy20.csv",  this.d3.autotype),
        self.d3.csv("https://labs.waterdata.usgs.gov/visualizations/data/gw-conditions-site-coords.csv",  this.d3.autotype), 
        self.d3.csv("https://labs.waterdata.usgs.gov/visualizations/data/gw-conditions-daily-proportions.csv",  this.d3.autotype),
        self.d3.csv("https://labs.waterdata.usgs.gov/visualizations/data/gw-conditions-time-labels.csv",  this.d3.autotype),
        ];
        Promise.all(promises).then(self.callback); // once it's loaded
      },
      callback(data) {
        // assign data

        // builds legend, has row for each category
        this.quant_peaks = data[0]; 

        // gwl site level timeseries data to make peak animation
        // row for each day/frame, col for each site
        // first column is the day, subsequent are named "gwl_" + site_no
        // site values are svg scaled svg positions for the animation
        this.date_peaks = data[1]; 

        // site coordinates for map
        // TODO: pre-draw on map and pick up with d3
        // requires duplicating map style in R so looks consistent on load
        // need to consider how to handle sites with no data on the first date 
        // variables: x, y, site_no, aqfr_type
        var site_coords = data[2]; 

        // proportion of sites by each category over time
        // variables: Date, day_seq (an integer from 1 to the last day), n_sites, and a column for each gwl category
        var site_count = data[3]; // number of sites x quant_category x day_seq

        // annotations for the timeline
        // R pipeline pulls out each month and the year for time labels
        // TODO: incorporate additional event annotations 
        var time_labels = data[4]; 

        // days in sequence
        var day_seq = this.date_peaks.columns
        day_seq.shift(); // drop first col with site_no

        // sites 
        this.sites_list = site_coords.map(function(d)  { return d.site_no })
        var n = this.sites_list.length // to create nested array for indexing in animation

        // site placement on map
        var sites_x = site_coords.map(function(d) { return d.x })
        var sites_y = site_coords.map(function(d) { return d.y })

        // reorganize - site is the key with gwl for each day of the wy
        // can be indexed using site key (gwl_#) - and used to bind data to DOM elements
        var peaky = [];
        for (i = 1; i < n; i++) {
            var key = this.sites_list[i];
            var day_seq = this.date_peaks.map(function(d){  return d['day_seq']; });
            var gwl = this.date_peaks.map(function(d){  return d[key]; });
            var site_x = sites_x[i];
            var site_y = sites_y[i];
            peaky.push({key: key, day_seq: day_seq, gwl: gwl, site_x: site_x, site_y: site_y})
        };

        // same for timeseries data but indexed by percentile category
        var quant_cat = [...new Set(this.quant_peaks.map(function(d) { return d.quant}))];
        
        var n_quant = quant_cat.length
        var percData = [];
          for (i = 0; i < n_quant; i++) {
          var key_quant = quant_cat[i];
          var day_seq = site_count.map(function(d){ return d['day_seq']});
          var perc = site_count.map(function(d){ return d[key_quant]});
          percData.push({key_quant: key_quant, day_seq: day_seq, perc: perc})
          };

        this.days = site_count.map(function(d) { return  d['day_seq']})
        //this.dates = site_count.map(function(d) { return  d['Date']}) // was used for date ticker
        this.n_days = this.days.length
     
        // set up scales
        this.setScales(); // axes, color, and line drawing fun
        this.makeLegend();

        // draw the map
        var map_svg = this.d3.select("svg.map")
        this.drawFrame1(map_svg, peaky);

        // animated time chart
        var time_container = this.d3.select("#line-container");
        this.drawLine(time_container, percData);
        this.addButtons(time_container, time_labels);

        // control animation
        this.animateLine(this.start);
        this.animateGWL(this.start);
        var play_container = this.d3.select("#play-container");
        this.playButton(play_container, "200","50");

      },
      addButtons(time_container, time_labels){
        const self = this;
       // timeline events/"buttons"
       // want these to be buttons that rewind the animation to the date
       // and also drive annotations to events

        var button_month = time_container.select('svg')
          .append("g")
          .attr("transform", "translate(20," + 120 + ")")
          .attr("z-index", 100)

        // month points on timeline
        button_month.selectAll(".button_inner")
          .data(time_labels).enter()
          .append("circle")
          .attr("class", function(d,i) { return "button_inner inner_" + d.month_label + "_" + d.year } ) 
          .attr("r", 5)
          .attr("cx", function(d) { return self.xScale(d.day_seq) })
          .attr("cy", 0)
          .attr("stroke", "white")
          .attr("stroke-width", "2px")
          .attr("fill", this.button_color)

        // month labels
        button_month.selectAll(".button_name")
          .data(time_labels)
          .enter()
          .append("text")
          .attr("class", function(d,i) { return "button_name name_" + d.month_label + "_" + d.year } ) 
          .attr("x", function(d) { return self.xScale(d.day_seq)-10 }) // centering on pt
          .attr("y", 25)
          .text(function(d, i) { return d.month_label })
          .attr("text-align", "start")

        // filter to just year annotations for first month they appear
        var year_labels = time_labels.filter(function(el) {
          return el.year_label >= 2000;
        });

        // add year labels to timeline
        button_month.selectAll(".button_year")
          .data(year_labels)
          .enter()
          .append("text")
          .attr("class", function(d,i) { return "button_year button_" + d.year } ) 
          .attr("x", function(d) { return self.xScale(d.day_seq)-10 }) // centering on pt
          .attr("y", 45)
          .text(function(d, i) { return d.year })

        // chart title
        button_month
          .append("text")
          .attr("class", function(d,i) { return "axis_label" } ) 
          .attr("x", function(d) { return self.xScale(1)-40 }) // centering on pt
          .attr("y", -120)
          .text(function(d, i) { return "Wells by groundwater level" })


      },
      drawLine(time_container, prop_data) {
        const self = this;

        var line_height = 250;
        var y_nudge = 20;

        // set up svg for timeline
        var svg = time_container
          .append("svg")
          .attr("width", "100%")
          .attr("preserveAspectRatio", "xMinYMin meet")
          .attr("viewBox", "0 -20 " + this.width + " " + line_height)
          .attr("id", "x-line")

        // define axes
        var xLine = this.d3.axisBottom()
          .scale(this.xScale)
          .ticks(0).tickSize(0);

        var yLine = this.d3.axisLeft().tickFormat(this.d3.format('~%'))
          .scale(this.yScale)
          .ticks(2).tickSize(6);

        // draw axes
        var xliney = svg.append("g")
          .call(xLine)
          .attr("transform", "translate(20," + 120 + ")")
          .classed("liney", true)

        var yliney = svg.append("g")
          .call(yLine)
          .attr("transform", "translate(47," +  y_nudge + ")")
          .classed("liney", true)

        // style axes
        xliney.select("path.domain")
          .attr("id", "timeline-x")
          .attr("color", "white")
          .attr("stroke-width", "4px")

        yliney.select("path.domain")
          .attr("id", "timeline-y")
          .attr("color", "white")
          .attr("stroke-width", "4px")
          .attr('font-size', '5rem')

        // add line chart
        // line chart showing proportion of gages in each category
        var line_chart = svg.append("g")
          .classed("time-chart", true)
          .attr("id", "time-legend")
          .attr("transform", "translate(20," +  y_nudge + ")")

        // add line chart
        line_chart.append("g")
          .attr("fill", "none")
          .attr("stroke-linejoin", "round")
          .attr("stroke-linecap", "round")
          .selectAll("path")
          .data(prop_data)
          .join("path")
          .attr("d", d => self.line(d.perc))
          .attr("stroke", function(d) { return self.gwl_color(d.key_quant) })
          .attr("stroke-width", "3px")
          .attr("opacity", 0.7);

        // animate line to time
        line_chart.append("rect")
          .data(this.days)
          .classed("hilite", true)
          .attr("width", "5")
          .attr("height", "100")
          .attr("opacity", 0.5)
          .attr("fill", "grey")
          .attr("x", self.xScale(this.days[this.start]))

        // add date ticker
  /*      line_chart
        .append("text")
        .attr("class", "ticker-date") 
        .attr("x", self.xScale(365)) // centering on pt
        .attr("y", -10)
        .text( this.dates[this.start])
        .attr("text-anchor", "end") */

      },
      setScales(){

        // set color scale for path fill
        this.quant_color = this.d3.scaleThreshold()
          .domain([-40, -25, 25, 40])
          .range(this.pal_BuBr) 

        // set scale for path shape
        var quant_path = [...new Set(this.quant_peaks.map(function(d) { return d.path_quant}))];
        
        this.quant_path_gylph = this.d3.scaleThreshold()
          .domain([-40, -25, 25, 40])
          .range(quant_path.reverse()) 

        // x axis of line chart
        this.xScale = this.d3.scaleLinear()
          .domain([0, this.n_days-1])
          .range([this.mar/2, this.width-2*this.mar])

        // y axis of line chart
        this.yScale = this.d3.scaleLinear()
          .domain([0, 0.6]) // this should come from the data - round up from highest proportion value
          .range([100, 0])

        // line drawing 
        this.line = this.d3.line()
          .defined(d => !isNaN(d))
          .x((d, i) => this.xScale(this.days[i]))
          .y(d => this.yScale(d))

        // categorical color scale
        this.gwl_color = this.d3.scaleOrdinal()
          .domain(["Veryhigh", "High", "Normal", "Low","Verylow"])
          .range(this.pal_BuBr)

      },
      playButton(svg, x, y) {
        const self = this;
         var svg_play = svg
          .append("svg")
          .attr("width", x)
          .attr("height", y)
          .attr("preserveAspectRatio", "xMinYMin meet")
          .attr("viewbox", "0 0 " + x + " " + y)

        var button = svg_play.append("g")
          .attr("transform", "translate("+ 0 +","+ 0 +")")
          .attr("class", "play_button");

        button
          .append("rect")
          .attr("width", 100)
          .attr("height", 40)
          .attr("rx", 4)
          .style("color", "black")
          .style("fill","transparent")
          .attr("stroke-width", "1px")
          .classed("pressMe", true);

        svg_play
          .append("text")
          .text("Play")
          .attr("x", 42)
          .attr("y", 30)
          .attr("font-size", "1.5rem")
          .attr("font-weight", "600")

        // append hover title
        button
          .append("title")
          .text("replay")

        button
          .append("path")
          .attr("d", "M7.5 7.5 L7.5 35 L32.5 20 Z")
          .style("fill", "white")
          .style("stroke", "black")
          .attr("stroke-width", "2px");
            
        button.select("rect")
          .on("mousedown", function() {
            self.pressButton(self.isPlaying)
          });
      },
      pressButton(playing) {
        const self = this;

        // trigger animation if animation is not already playing
        if (playing == false) {
          self.animateLine(0);
          self.animateGWL(0);
        }
      },
      resetPlayButton() {
        const self = this;

        // reset global playing variable to false now that animation is complete
        self.isPlaying = false;

        // undim button
        let button_rect = this.d3.selectAll(".play_button").selectAll("rect")
          .style("fill", '#9b6adb8e')

      },
      animateLine(start){
        // animates grey line on timeseries chart to represent current timepoint
        const self = this;
        var line_height = 250;
        
        // set indicator for play button
        self.isPlaying = true

        // dim play button rectangle
        let button_rect = this.d3.selectAll(".play_button").selectAll("rect")
        button_rect
            .style("fill", "#d6d6d6")


        if (start < this.n_days){
          this.d3.selectAll(".hilite")
          .transition()
            .duration(this.day_length) 
            .attr("x", self.xScale(this.days[start]))
          .end()
          .then(() => this.animateLine(start+1))

         /*  this.d3.selectAll(".ticker-date")
          .transition()
            .duration(this.day_length) 
            .text(this.dates[start])
          .end()
          .then(() => this.animateLine(start+1)) */

        } else {
          this.d3.selectAll(".hilite")
            .transition()
            .duration(this.day_length) 
            .attr("x", self.xScale(this.days[this.n_days-1]))

          // once animation has completed, reset color of play button
          // and set isPlaying to false
          button_rect
              .transition()
              .delay(this.day_length*(this.n_days-1))
              .on("end", self.resetPlayButton);
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
      },
      makeLegend(){
        const self = this;

        var legend_height = 200;
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
          .attr("transform", "translate(0, 0)")
        
        // legend elements
        var legend_keys = ["Very low", "Low", "Normal", "High","Very high"]; // labels
        var perc_label = ["0.00 - 0.10", "0.10 - 0.25" ,"0.25 - 0.75", "0.75 - 0.90", "0.90 - 1.00"] // percentile ranges

        // draw path shapes and labels
        var legend_title_x = 0;
        var legend_label_x = 56;
        legend_peak
          .append("text")
          .text("Groundwater levels")
          .attr("x", legend_title_x)
          .attr("y", "20")
          .style("font-size", "1.5rem")
          .style("font-weight", 600) // matching css of .axis_labels
          .attr("text-anchor", "start")

        legend_peak
          .append("text")
          .text("Percentile based on historic")
          .attr("x", legend_title_x)
          .attr("y", "40")
          .style("font-size", "1rem")
          .style("font-weight", 400)
          .attr("text-anchor", "start")

          legend_peak
          .append("text")
          .text("daily record at each site")
          .attr("x", legend_title_x)
          .attr("y", "60")
          .style("font-size", "1rem")
          .style("font-weight", 400)
          .attr("text-anchor", "start")

      
        var label_end = 180; // moves legend keys and labels up and down
        var label_space = 23; // spacing between legend elements
        
        // add glyphs
        legend_peak.selectAll("peak_symbol")
          .data(this.quant_peaks)
          .enter()
          .append("path")
            .attr("fill", function(d){return self.gwl_color(d.quant)})
            .attr("d", function(d){return d["path_quant"]})
            .attr("transform", function(d, i){return "translate(" + 95 + ", " + ((label_end-8)-20*i) + ") scale(.85)"})
            .attr("id", function(d){return d["quant"]})
            .attr("class", "peak_symbol")

        // add categorical labels ranked from very low to very high
        legend_peak.selectAll("mylabels")
          .data(legend_keys)
          .enter()
          .append("text")
            .attr("x", legend_label_x+20)
            .attr("y", function(d,i){ return label_end - (i*label_space)}) 
            .text(function(d){ return d})
            .attr("text-anchor", "end")
            .style("alignment-baseline", "middle")
            .style("font-weight", "600")
            .attr("font-size", "16px")

        // label percentile ranges in each category
         legend_peak.selectAll("percLabels")
          .data(perc_label)
          .enter()
          .append("text")
            .attr("x", legend_label_x+60)
            .attr("y", function(d,i){ return label_end - (i*label_space)}) 
            .text(function(d){ return d})
            .attr("text-anchor", "start")
            .style("alignment-baseline", "middle")
            .attr("font-size", "16px")

      },
      drawFrame1(map_svg, data){         
        // draw the first frame of the animation
        const self = this;

          // draw sites with D3
          var start = this.start;
            this.peak_grp = map_svg.selectAll("path.gwl_glyph")
              .data(data, function(d) { return d ? d.key : this.class; }) // binds data based on class/key
              .join("path") // match with selection
              .attr("transform", d => `translate(` + d.site_x + ' ' + d.site_y + `) scale(0.35 0.35)`)

            // draws a path for each site, using the first date
            this.peak_grp 
             .attr("class", function(d) { return d.key })
             .attr("fill", function(d) { return self.quant_color(d.gwl[start]) }) 
             .attr("opacity", ".5")
             .attr("d", function(d) { return self.quant_path_gylph(d.gwl[start]) }) //{ return "M-10 0 C -10 0 0 " + d.gwl[start] + " 10 0 Z" } ) // d.gwl.# corresponds to day of wy, starting with 0

      },
      animateGWL(start){
        const self = this;
      // animate path d and fill by wy day    
    
        if (start < this.n_days-2){
        
          this.peak_grp
            .transition()
            .duration(this.day_length)
            .each(function(d,i) {
              let current_path = self.d3.select(this)
              var today = self.quant_path_gylph(d.gwl[start])
              var yesterday = self.quant_path_gylph(d.gwl[start-1])
              if(today != yesterday){
                self.animatePathD(start, current_path)
              }
            })
            .end() // end is important because it waits for EVERY element to finish the transition before callback, keeps things in sync
            .then(() => this.animateGWL(start+1)) // loop animation increasing by 1 day
        } else {
      // if it's the last day of the water year, stop animation 
          this.peak_grp
            .transition('daily_gwl')
            .duration(this.day_length)  // duration of each day
            .attr("d", function(d) { return self.quant_path_gylph(d.gwl[this.n_days-1]) })//{ return "M-10 0 C -10 0 0 " + d.gwl[this.n_days-1] + " 10 0 Z" })
            .attr("fill", function(d) { return self.quant_color(d.gwl[this.n_days-1]) })
        }
      },
      animatePathD(start, current_path){
        const self = this;
        current_path
          .transition('daily_gwl')
          .attr("d", function(d) { 
            return self.quant_path_gylph(d.gwl[start])
            })
          .attr("fill", function(d) { return self.quant_color(d.gwl[start]) })
      }
    }
}
</script>
<style scoped lang="scss">
$dark: #323333;
// each piece is a separate div that can be positioned or overlapped with grid
// mobile first
#grid-container {
  display: grid;
  padding-right: 2rem;
  margin: 1rem;
  width: 100%;
  height: auto;
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
  padding-bottom: 0px;
  display: flex;
  justify-content: center;
  align-items: center;
  svg.map {
    max-height: 650px;
  }
}
#text-container {
  grid-area: text;
  padding:20px;
  padding-top: 0px;
  // controlling positioning within div as page scales
  display: flex;
  justify-content: center;
  align-items: top;
}
#line-container {
  grid-area: line;
  margin-bottom: 10px;
}
#play-container {
  grid-area: play;
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
    color:$dark;
    height: auto;
    padding: 4px;
    padding-bottom: 0;
    padding-left: 0;
  }
}

// drop shadow on map outline
#bkgrd-map-grp {
  filter: drop-shadow(0.2rem 0.2rem 0.5rem rgba(38, 49, 43, 0.15));
  stroke-width: 0.2;
  color: white;
  fill: white;
}
// annotated timeline
.liney {
  stroke-width: 2px;
}

// desktop
@media (min-width:700px) {
  #grid-container {
    margin: 50px;
    grid-template-columns: 2fr 5fr;
    grid-template-areas:
    "title map"
    "legend map"
    "play map"
    "line line"
  }
  .title {
  text-align: left;
  }
  #legend-container {
    display: flex;
    justify-content: flex-start;
    padding-left: 20px;
    align-items: center;
  }
  #line-container {
  grid-area: line;
}
#map-container{
  margin-top: 50px;
  margin-right: 20px;
  svg.map {
    max-height: 900px;
  }
}
}
@media (min-width:1024px) {
  #grid-container {
    margin: 50px;
    grid-template-columns: 2fr 5fr;
    grid-template-areas:
    "title map"
    "legend map"
    "play map"
    "line line"
  }
  .title {
  text-align: left;
  margin-bottom: 0;
  padding-bottom: 0;
  }
  #legend-container {
    display: flex;
    justify-content: flex-start;
    padding-left: 20px;
    align-items: center;
  }
  #line-container {
  grid-area: line;
  padding-left: 20px;
}
#map-container{
  margin-top: 0px;
  margin-bottom: 0px;
  margin-right: 20px;
  svg.map {
    max-height: 75vh;
  }
}
#play-container {
  padding-left: 20px;
}
}
// glyph paths
.gwl_glyph {
  stroke: none; 
  fill-opacity: 50%;
}
.pressMe:active {
  background-color: #9b6adb8e;
  box-shadow: 0 5px #666;
  transform: translateY(4px);
}
.pressMe:hover {
  background-color: #b996e78e;
  box-shadow: 0 1px #666;
  transform: translateY(1px);
}
text.tick {
  font-size: 1rem;

}
</style>