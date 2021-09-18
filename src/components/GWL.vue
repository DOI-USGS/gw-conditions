<template>
  <section>
      <div id="title-container">
        <h2 class="title" id="title-main">U.S. Groundwater Conditions</h2>
        <h3 class="title" id="title-sub">The low down on flow down low</h3>
      </div>
<div id="grid-container">
    <div id="map-container">
       <GWLmap id="map_gwl" class="map" />
    </div>
    <div id="legend-container" />
    <div id="time-container" />
    <div id="dot-container" />
    <div id="line-container" />
    </div>
  </section>
</template>
<script>
import * as d3Base from 'd3';
import GWLmap from "@/assets/anomaly_peaks.svg";
import { TimelineMax, Draggable, TweenMax } from "gsap/all"; 

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
      margin: { top: 50, right: 50, bottom: 50, left: 50 },

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
      day_length: 20, // frame duration in milliseconds
      current_time: 0,
      //x:  0,
      sites_list: null,
      //t2: null,

    }
  },
  mounted(){
      this.$gsap.registerPlugin(Draggable); // register gsap plugins for scrollTrigger 
      this.d3 = Object.assign(d3Base);

      // resize
      this.width = window.innerWidth - this.margin.left - this.margin.right;
      this.height = window.innerHeight*.5 - this.margin.top - this.margin.bottom;

      // read in data
      //this.callS3("https://labs.waterdata.usgs.gov/visualizations/data/gw-conditions-wy20.csv");
      this.loadData();   

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
        self.d3.csv(self.publicPath + "quant_peaks.csv",  this.d3.autotype), // used to draw legend shapes
        self.d3.csv("https://labs.waterdata.usgs.gov/visualizations/data/gw-conditions-wy20.csv",  this.d3.autotype),
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
        .range(["#1A3399","#479BC5","#669957","#C1A53A","#7E1900"]) // using a slightly darker green

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

      // animated bar chart
        this.legendBarChart(this.percData);
        //this.animateTimeline(); // set up scrubber

        this.drawLine(this.days)

      },
      createPanel(month) {
        var tl = new TimelineMax();
        tl.to("tl_" + month)
        // add rest of this
        return tl;
      },
      drawLine(date_range) {
        //console.log(date_range)
        var line_width = 900;
        var line_height = 200;
        var mar = 25;

        var month_list = [1, 30, 61, 80, 110, 140, 170, 200, 230, 261, 291, 322]
        var month_names = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Oct", "Nov", "Dec"]

      var svg = this.d3.select("#line-container")
        .append("svg")
        .attr("width", "100vw")
        .attr("height", line_height)
        .attr("id", "x-line")

        // scale space
      var xScale = this.d3.scaleLinear()
        .domain([Math.min(date_range), Math.max(date_range)])
        .range([mar, line_width-mar])

      // axes
      var xLine = this.d3.axisBottom()
        .scale(xScale)
        .ticks(0).tickSize(0);

      var liney = svg.append("g")
        //.attr("transform", "translate(0," + 170 + ")")
        //.classed("x-line", true)
        .call(xLine)
        .attr("transform", "translate(0," + 20 + ")")
        .classed("liney", true)

      liney.select("path")
        .attr("color", "lightgrey")
        .attr("stroke-width", "3px")
        //add ticks for each month
        // add ticks for given dates, or periods?
        // make them glowy buttons

        var button = this.d3.button()
        .on('press', function(d, i) { console.log("Pressed", d, i, this.parentNode)})
        .on('release', function(d, i) { console.log("Released", d, i, this.parentNode)});
var data = [{label: "Click me",     x: width / 4, y: height / 4 },
            {label: "Click me too", x: width / 2, y: height / 2 }];
      var buttons = svg.selectAll('.button')
      .data(data)
      .enter()
      .append('g')
      .attr('class', 'button')
      .call(button);

      },
      initTime(){
        var tl_jan = new TimelineMax(); //TimelineMax permits repeating animation
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
        // separate timelines for each month

        createPanel(".gwl_")

        // add to parent timeline
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
        .add(tl_dec) // nest sites wtihin each month?

      },
      animateTimeline(){
        // create props
        //let target2 = this.d3.selectAll(".bars");
        let knob2 = document.getElementById("knob2");
        let knob2Rect = knob2.getBoundingClientRect();
        let volumeBar = document.getElementById("scrub-bar");
        let volRect = volumeBar.getBoundingClientRect();
        let range2 = document.getElementById("range2");

        // scales
        var w = 200;
        var h = 110;

        var xScale = this.d3.scaleLinear()
        .domain([0, 0.5])
        .range([0, w])

      // scale to convert x position to time?
        //var 

        // create dragggable selector
        Draggable.create(knob2, {
          type: "x", 
          trigger: "#scrub-bar",
          bounds:  "#scrub-bar",
          edgeResistance: 1,
          lockAxis: true,
          cursor: "pointer",
          onDrag: updateRange,
          onPress: updateRange,
          onClick: updatePosition,
          //onComplete: console.log(this.x),

        });

        // init timeline
        let t2 = new TimelineMax({paused:true, duration: 0.001, repeat: -1});
 
        // array of units to loop across - gage sites / categories
        var quant_cat = [...new Set(this.quant_peaks.map(function(d) { return d.quant}))];
        for(var i=0;i<quant_cat.length;i++){
            quant_cat[i]="rect#"+quant_cat[i];
        }

        var xScale = this.d3.scaleLinear()
        .domain([0,0.5])
        .range([0, 225])

        var w = 600; // for hilite bar

        // line chart showing proportion of gages in each catego
        var xpos = this.d3.scaleLinear()
        .domain([1, 365])
        .range([5, w-5])
        
        var name_in = 'path.' + this.sites_list[210];

        this.d3.select(name_in)
        .classed("bigbaby", true)
        .attr("fill", "purple")
        .attr("opacity", 1)

        // timeline driving animation of multiple objects
        var time_now = 0;
        t2.to(quant_cat, {  width: i => xScale(this.percData[i].perc[time_now]) }); // many things at once but only for a day

        for (i = 0; i < 366; i += 1) {
           var time_now = time_now + 1;
           t2
           .to(quant_cat[0], {  width: xScale(this.percData[0].perc[time_now])}, time_now)
           .to(quant_cat[1], {  width: xScale(this.percData[1].perc[time_now])}, time_now)
           .to(quant_cat[2], {  width: xScale(this.percData[2].perc[time_now])}, time_now)
           .to(quant_cat[3], {  width: xScale(this.percData[3].perc[time_now])}, time_now)
           .to(quant_cat[4], {  width: xScale(this.percData[4].perc[time_now])}, time_now) 
           .to(".hilite", { x: xpos(time_now) }, time_now)
           

           /* for (let j = 0; j < this.sites_list.length; j++) {
             //console.log(this.peaky[j].gwl[time_now])

            t2.to('path.' + this.sites_list[j], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[j].gwl[time_now] + " 10 0 Z" }, position: time_now 
            })
           } */

           /* t2 
           .to('path.' + this.sites_list[211], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[211].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[212], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[212].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[213], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[213].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[214], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[214].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[215], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[215].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[216], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[216].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[217], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[217].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[218], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[218].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[219], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[219].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[1210], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[1210].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[1211], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[1211].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[1212], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[1212].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[1213], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[1213].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[1214], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[1214].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[1215], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[1215].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[1216], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[1216].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[1217], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[217].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[1218], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[1218].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[1219], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[1219].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[1210], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[1210].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[1211], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[1211].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[312], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[312].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[313], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[323].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[314], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[314].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[315], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[315].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[316], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[316].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[2317], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[317].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[318], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[318].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[319], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[319].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[211], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[411].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[414], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[414].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[413], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[413].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[414], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[414].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[415], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[415].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[416], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[416].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[417], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[417].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[418], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[418].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[419], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[419].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[1410], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[1410].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[1411], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[1411].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[1414], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[1414].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[1413], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[1413].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[1414], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[1414].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[1415], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[1415].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[1416], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[1416].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[1417], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[417].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[1418], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[1418].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[1419], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[1419].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[1410], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[1410].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[1411], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[1211].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[512], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[512].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[515], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[525].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[514], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[514].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[515], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[515].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[516], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[516].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[517], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[517].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[518], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[518].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[519], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[519].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[611], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[611].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[612], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[612].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[613], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[613].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[614], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[614].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[615], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[615].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[616], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[616].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[617], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[617].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[618], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[618].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[619], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[619].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[1610], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[1610].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[1611], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[1611].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[1616], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[1616].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[1613], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[1613].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[1614], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[1614].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[1615], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[1615].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[1616], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[1616].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[1617], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[617].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[1618], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[1618].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[1619], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[1619].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[1610], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[1610].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[1611], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[1611].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[716], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[716].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[717], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[717].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[714], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[714].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[715], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[715].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[716], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[716].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[717], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[717].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[718], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[718].gwl[time_now] + " 10 0 Z" },position: time_now })
           .to('path.' + this.sites_list[719], { attr: { d: "M-10 0 C -10 0 0 " + this.peaky[719].gwl[time_now] + " 10 0 Z" },position: time_now }) */
        }

         

         t2.duration(0.0005).play();
  
        // struggling to figure out how to write this loop
        // need to use 'add' or 'to' to add targets to the timeline for each day tween
        // that uses integers 1:end to index data values for each i (site)
        // want to be able to use playback controls
      
        function updatePosition () {
  
          knob2Rect = knob2.getBoundingClientRect();
          volRect = volumeBar.getBoundingClientRect();
          
          TweenMax.set(knob2, { x: this.pointerX - volRect.left - knob2Rect.width / 2 });
          TweenMax.set(range2, { width: knob2Rect.left + knob2Rect.width - volRect.left });

          updateRange();
  
      };
      function updateRange () {
        const self = this;
        
        var x = this.x;
        if (x < 0.0001 && x > -0.0001) {
        x = 0;
        }
        
        let volRect = volumeBar.getBoundingClientRect();
        let knob2Rect = knob2.getBoundingClientRect();
        
        t2.progress(x / (volRect.width - knob2Rect.width));
        
        TweenMax.set(range2, { width: knob2Rect.left + knob2Rect.width - volRect.left });

        };
      },
      makeLegend(){

        var legend_height = 250;
        var legend_width = 400;

        // make a legend 
          var legend_peak = this.d3.select("#legend-container")
          .append("svg")
          .attr("width", legend_width)
          .attr("height", legend_height)
          .attr("id", "map-legend")
          .append("g").classed("legend", true)

          var legend_keys = ["Very low", "Low", "Normal", "High","Very high"];
          var shape_dist = [5,25,42,42,60,83,103];

        // draw path shapes
        legend_peak.selectAll("peak_symbol")
          .data(this.quant_peaks)
          .enter()
          .append("path")
            .attr("fill", function(d){return d["color"]})
            .attr("d", function(d){return d["path_quant"]})
            .attr("transform", function(d, i){return "translate(130, " + (150-shape_dist[i]) + ") scale(.8)"})
            .attr("id", function(d){return d["quant"]})
            .attr("class", "peak_symbol")

        // add categorical labels very low - very high
        legend_peak.selectAll("mylabels")
          .data(legend_keys)
          .enter()
          .append("text")
            .attr("x", 110)
            .attr("y", function(d,i){ return 150 - (i*22)}) // 100 is where the first dot appears. 25 is the distance between dots
            .text(function(d){ return d})
            .attr("text-anchor", "end")
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
          this.legendTimeChart(this.percData, start);
      },
      animateGWL(start){
         const self = this;
        // animate path d and fill by wy day    
        if (start < 364){
      // transition through days in sequence
        this.peak_grp
        .transition()
        .duration(this.day_length)  // duration of each day
        .attr("d", function(d) { return "M-7 0 C -7 0 0 " + d.gwl[start]*1.5 + " 7 0 Z" })
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
        var w = 200;
        var h = 110;

        var xScale = this.d3.scaleLinear()
        .domain([0, 0.5])
        .range([0, w])

        var yScale = this.d3.scaleBand()
        .domain(["Veryhigh", "High", "Normal", "Low", "Verylow"])
        .range([h, 0])

        var bar_color = this.d3.scaleOrdinal()
        .domain(["Veryhigh", "High", "Normal", "Low","Verylow"])
        .range(["#1A3399","#479BC5","#D1ECC9","#C1A53A","#7E1900"])

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
            return 146 - yScale(d.key_quant)
          })
          .attr("x", function(d) {
            //return w + xScale(d.perc[start])
            return 150
          })
          .attr("id", function(d){ return d.key_quant})
          .attr("height", "12")
          .attr("fill", function(d) { return bar_color(d.key_quant) })
          .attr("opacity", 0.8)

          // axes
          var xAxis = this.d3.axisBottom()
          .scale(xScale)
          .ticks(5);

          svg.append("g")
          .attr("transform", "translate(150," + 170 + ")")
          .classed("x-axis", true)
          .call(xAxis)

          // then animate it
          this.animateBarChart(start);

      },
      animateBarChart(start){
        
         var xScale = this.d3.scaleLinear()
        .domain([0,0.5])
        .range([0, 225])

        if (start < 364){
        this.d3.selectAll(".bars")
         .transition()
          .duration(this.day_length) 
           .attr("x", function(d) {
            return 150
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
        .ease(this.d3.easeCubic)
        .attr("x", function(d) {
            return 150
          })
          .attr("width", function(d) {
            return xScale(d.perc[364]);
          })
      }

      },
      legendTimeChart(data, start){
        // scales
        var w = 600;
        var h = 300;

        // line chart showing proportion of gages in each category
        var svg = this.d3.select("#time-container")
          .append("svg")
          .attr("width", w)
          .attr("height", h)
          .attr("id", "time-legend")
          .append("g").classed("time-chart", true)


        var x = this.d3.scaleLinear()
        .domain([1, 365])
        .range([5, w-5])

        var y = this.d3.scaleLinear()
        .domain([0, 0.5])
        .range([150, 50])

        var bar_color = this.d3.scaleOrdinal()
        .domain(["Veryhigh", "High", "Normal", "Low","Verylow"])
        .range(["#1A3399","#479BC5","#D1ECC9","#C1A53A","#7E1900"])

        var line = this.d3.line()
          .defined(d => !isNaN(d))
          .x((d, i) => x(this.days[i]))
          .y(d => y(d))

        // add line chart
      const path = svg.append("g")
          .attr("fill", "none")
          .attr("stroke-linejoin", "round")
          .attr("stroke-linecap", "round")
        .selectAll("path")
        .data(data)
        .join("path")
        .attr("d", d => line(d.perc))
        .attr("stroke", function(d) { return bar_color(d.key_quant) })
        .attr("stroke-width", "3px")
        .attr("opacity", 0.7);

        var xAxis = this.d3.axisBottom()
          .scale(x)
          .ticks(5);

        svg.append("g")
          .classed("x-axis", true)
          .attr("transform", "translate(0," + 155 + ")")
          .call(xAxis.tickPadding(4).tickSize(0).tickValues([1,365]))

          var start = 0;

        svg.append("rect")
          .data(this.days)
          .classed("hilite", true)
          .attr("transform", "translate(5, 35)") 
          .attr("width", "5")
          .attr("height", "120")
          .attr("opacity", 0.5)
          .attr("fill", "grey")
          .attr("x", x(this.days[start]))

          //var slider = svg.append("g")
          //.attr("class", "slider")
          //.attr("transform", "translate(" + 50 + "," + h/5 + ")");

          //slider.append("line")
           // .attr("class", "track")
           // .attr("x1", x.range()[0])
           // .attr("x2", x.range()[1])
         
          this.animateTime(start)
      },
      animateTime(start){
        var w = 600;
        var h = 300;

        var x = this.d3.scaleLinear()
        .domain([1, 365])
        .range([5, w-5])

        if (start < 364){
        this.d3.selectAll(".hilite")
         .transition()
          .duration(this.day_length) 
          .attr("x", x(this.days[start]))
        .end()
        .then(() => this.animateTime(start+1))
      } else {
       this.d3.selectAll(".hilite")
        .transition()
        .duration(this.day_length) 
        .attr("x", x(this.days[364]))
      }
  },
  legendDot(data, start){
        // scales
        var w = 600;
        var h = 300;

        // line chart showing proportion of gages in each category
        var svg = this.d3.select("#dot-container")
          .append("svg")
          .attr("width", w)
          .attr("height", h)
          .attr("id", "dot-legend")
          .append("g").classed("dot-chart", true)


        var x = this.d3.scaleLinear()
        .domain([1, 365])
        .range([5, w-5])

        var y = this.d3.scaleLinear()
        .domain([0, 0.5])
        .range([150, 50])

        var bar_color = this.d3.scaleOrdinal()
        .domain(["Veryhigh", "High", "Normal", "Low","Verylow"])
        .range(["#1A3399","#479BC5","#D1ECC9","#C1A53A","#7E1900"])

        // add line chart
      const path = svg.append("g")
        .selectAll("circle")
        .data(data)
        .join("circle")
        .attr("fill", function(d) { return bar_color(d.key_quant) })
        .attr("opacity", 0.7)
        .attr("r", 0.7);

        var xAxis = this.d3.axisBottom()
          .scale(x)
          .ticks(5);

        var start = 0;

        svg.append("circle")
          .data(this.days)
          .classed("hilite", true)
          .attr("transform", "translate(5, 35)") 
          .attr("width", "5")
          .attr("height", "120")
          .attr("opacity", 0.5)
          .attr("fill", "grey")
          .attr("x", x(this.days[start]))

          this.animateDot(start)
      }
    }
}
</script>
<style scoped lang="scss">
#map-container{
  width: auto;
  //height: 85vh;
  margin-left: 5%;
  margin-top: 2%;
  margin-bottom: 0;
  position: relative;
  grid-area: map;

    .map {
    position: relative;
    left:0;
    top: 0;
    width: 90vw;
    max-width: 1000px;
    max-height: 600px;
    height: auto;

  }
}
// each piece is a separate div that can be positioned or overlapped with grid
#grid-container {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr 1fr;
  grid-template-rows: 2fr 1fr;
  grid-template-areas:
  "map map map map"
  "map map map map"
  "line line line line"
  "legend time time time"
  //". scrub scrub ."
}
#line-container {
  grid-area: line;
}
#legend-container {
  grid-area: legend;
  margin-bottom: 0;
  height: auto;
}
#time-container {
  grid-area: time;
  margin: 2%;
  margin-bottom: 0;
  margin-right: 5%;
  height: auto;
}
#scrub-bar {
  grid-area: time;
  margin: 2%;
  margin-bottom: 0;
  margin-right: 5%;
  height: auto;
}
#title-container {
  //width: 100vw;
  height: auto;
  background-color: "pink"; //rgb(237, 237, 237);
  grid-area: title;
  h1, h2, h3 {
    width: 95vw;
    color:rgb(34, 33, 33);
    height: auto;
    padding: 4px;
    
  }
}
.title {
  text-align: right;
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
  color: #4b4a4a;
}

</style>