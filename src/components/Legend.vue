<template>
        <svg 
          id="legend"
          preserveAspectRatio="xMinYMin meet"
          viewBox="0 -10 500 60"
        >
          <line
            x1="455"
            x2="495"
            y1="25"
            y2="25"
            class="legend-line"
          />
          <line
            x1="5"
            x2="45"
            y1="25"
            y2="25"
            class="legend-line"
          />
          <line
            x1="55"
            x2="120"
            y1="25"
            y2="25"
            class="legend-line"
          />
          <line
            x1="135"
            x2="365"
            y1="25"
            y2="25"
            class="legend-line"
          />
          <line
            x1="385"
            x2="445"
            y1="25"
            y2="25"
            class="legend-line"
          />
          <line
          x1="1"
          x2="1"
          y1="20"
          y2="30"
          class="legend-tick"
          />
          <line
          x1="499"
          x2="499"
          y1="20"
          y2="30"
          class="legend-tick"
          />
          <line
          x1="50"
          x2="50"
          y1="20"
          y2="30"
          class="legend-tick"
          />
          <line
          x1="450"
          x2="450"
          y1="20"
          y2="30"
          class="legend-tick"
          />
          <line
          x1="125"
          x2="125"
          y1="20"
          y2="30"
          class="legend-tick"
          />
          <line
          x1="375"
          x2="375"
          y1="20"
          y2="30"
          class="legend-tick"
          />
          <text
          x="1"
          y="45"
          class="legend-text"
          >0
          </text>
          <text
          x="499"
          y="45"
          class="legend-text"
          >1
          </text>
          <text
          x="50"
          y="45"
          class="legend-text"
          >0.1
          </text>
          <text
          x="450"
          y="45"
          class="legend-text"
          >0.9
          </text>
          <text
          x="125"
          y="45"
          class="legend-text"
          >0.25
          </text>
          <text
          x="375"
          y="45"
          class="legend-text"
          >0.75
          </text>
          
          <text
          x="20"
          y="0"
          class="legend-label"
          >Very low
          </text>
          <text
          x="499"
          y="0"
          class="legend-label"
          >Very high
          </text>
          <text
          x="90"
          y="0"
          class="legend-label"
          >Low
          </text>
          <text
          x="410"
          y="0"
          class="legend-label"
          >High
          </text>
          <text
          x="250"
          y="0"
          class="legend-label"
          >Normal
          </text>
          <path
            id="Verylow"
            fill="#BF6200"
            d="M-10 0 C -10 0 0 45 10 0 Z"
            transform="translate(25, 25)"
            class="peak_symbol"
          />
          <path
            id="Low"
            fill="#FEB100"
            d="M-10 0 C -10 0 0 32 10 0 Z"
            transform="translate(90, 25)"
            class="peak_symbol"
          />
          <path
            id="Normal"
            fill="#B3B3B3"
            d="M-10 0 C -10 0 0 15 10 0 C 10 0 0 -15 -10 0 Z"
            transform="translate(250, 25)"
            class="peak_symbol"
          />
          <path
            id="High"
            fill="#2E9EC6"
            d="M-10 0 C -10 0 0 -32 10 0 Z"
            transform="translate(410, 25)"
            class="peak_symbol"
          />
          <path
            id="Veryhigh"
            fill="#28648A"
            d="M-10 0 C -10 0 0 -45 10 0 Z"
            transform="translate(475, 25)"
            class="peak_symbol"
          />
        </svg>
            
</template>
<script>

export default {
  name: "Legend",
    components: {
      
    },
    data() {
    return {
      
     // Blue-Brown categorical color scale
      verylow: "#BF6200",
      low: "#FEB100",
      normal: "#B3B3B3",
      high: "#2E9EC6",
      veryhigh: "#28648A",
      pal_BuBr: null,

    }
  }      
}
</script>
<style scoped lang="scss">
$dark: rgba(54, 54, 54, 0.7);

// each piece is a separate div that can be positioned or overlapped with grid
// mobile first
section {
  width: 92vw;
  margin: auto;
}
#grid-container {
  display: grid;
  max-width: 1600px;
  margin: auto;
  height: auto;
  vertical-align: middle;
  overflow: hidden;
  grid-template-columns: 1fr;
  grid-template-areas:
  "title"
  "map"
  "container"
  "line"
  "text"
}
#map-container{
  grid-area: map;
  padding: 0rem;
  padding-bottom: 0px;
  margin-top: 0.5rem;
  display: flex;
  justify-content: center;
  align-items: center;
  svg.map {
    max-height: 68vh;
  }
}
#line-container {
  grid-area: line;
  width: 100%;
  max-width: 700px;
  margin: auto;
  margin-bottom: 10px;

  svg{
    overflow: hidden;
  }
}
#legend-container {
  //grid-area: legend;
  width: 100%;
  max-width: 500px;
  float: left;
 // margin: 0;
  align-self: right;
  justify-self: end;
  svg{
    max-width: 500px;
    margin: auto;
    align-self: start;
    justify-self: start;
    overflow: visible;
  }
}
#title-container {
  grid-area: title;
  width: 100%;
  max-width: 700px;
  height: auto;
  margin: auto;
  align-items: start;
  h1, h2{
    margin-top: 1rem;
  }
  h3 {
    margin-top: 0.5rem;

  }
}
#text-container {
  grid-area: text;
  max-width: 700px;
  margin: 1rem auto;
}
#button-container {
  //grid-area: button;
  max-width: 100px;
  height: auto;
  float: right;
  margin: auto;
  text-align: right;
  //justify-content: center;
  //align-items: center;
  //max-width: 200px;
}
#container-container {
  grid-area: container;
  width: 100%;
  margin: auto;
  max-width: 700px;
  margin-bottom: 1rem;
 
}
.text-content {
  margin: 0.5rem auto;
  max-width: 700px;
}
.text-content:last-child {
  margin-bottom: 1rem;
}
#map-text {
  display: inline-block;
}
// drop shadow on map outline
#bkgrd-map-grp {
  filter: drop-shadow(0.2rem 0.2rem 0.5rem rgba(38, 49, 43, 0.45));
  stroke-width: 0.2;
  color: white;
  fill: white;
}
// pause/play button
#button-play {
  width: auto;
  max-width: 100px;
  height: auto;
  margin: auto;
  @media screen and (max-width: 550px) {
        font-size: 16px;
      }
}

// apply button attr from uswds
.usa-button--outline {
  background-color: $dark;
  color: white;
  appearance: none;
  border: 2px solid $dark;
  border-radius: 0.35rem;
  cursor: pointer;
  font-weight: 600;
  font-size: 1rem;
  padding: 0.5rem 0.75rem;
  text-align: center;
  text-decoration: none;
  overflow: visible;

}
button {
    appearance: auto;
    text-rendering: auto;
    letter-spacing: normal;
    word-spacing: normal;
    line-height: normal;
    align-items: center;
    box-sizing: border-box;
    margin: 0em;
    padding: 1px 4px;
}
[type=button], [type=reset], [type=submit], button {
    -webkit-appearance: button;
}
button:hover {
    background: white;
    color: $dark;
  box-shadow: 0 5px $dark;
}
button:active {
  background-color: $dark;
  color: white;
  box-shadow: 0 5px white;
  transform: translateY(4px);
}
// desktop
/* @media (min-width:700px) {
  #grid-container {
    grid-template-columns: 2fr 5fr;
    grid-template-areas:
    "title map"
    "legend map"
    "line line"
  }
  #legend-container {
    display: flex;
    justify-content: flex-start;
    align-items: start;
  }
}*/
/* @media (min-width:1024px) {
  #grid-container {
    grid-template-columns: 2fr 5fr;
    grid-template-areas:
    "title map"
    "legend map"
    "line line"
  }
} */
// legend styling
line.legend-line {
  stroke-dasharray: 3;
  stroke-width: 2;
  stroke: grey;
}
line.legend-tick {
  stroke-width: 2;
  stroke: grey;
}
text.legend-text {
  text-anchor: middle;
  font-size: 0.8rem;
  alignment-baseline: baseline;
}
text.legend-label {
  text-anchor: middle;
  font-size: 1rem;
  font-weight: 600;
  alignment-baseline: baseline;
}
.liney {
  color: black;
  stroke-width: 2px;
}

</style>