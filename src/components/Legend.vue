<template>
        <svg 
          id="legend"
          preserveAspectRatio="xMinYMin meet"
          viewBox="-25 -10 570 60"
          aria-labelledby="legendTitleID legendDescID"
          role="img"
        >
        <title id="legendTitleID">A legend classifying groundwater levels by percentile</title>
        <desc id="legendDescID">Groundwater percentiles are binned into 5 water level categories: very low (0-0.1), low (0.1-0.25), normal (0.25-0.75), high (0.75-0.9), and very high (0.9-1). Each category is represented by an arrow-like glyph that points up or down, depending on whether water levels are higher or lower than the historic record.</desc>
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

</style>