<template>
  <div id="header">
    <header
      id="navbar"
      class="header-nav"
      role="banner"
    >
      <div class="tmp-container">
        <a
          class="logo-header"
          href="https://labs.waterdata.usgs.gov/visualizations/vizlab-home/index.html#/"
          title="Home"
          target="_blank"
        >
          <img
            class="img"
            src="@/assets/usgsHeaderAndFooter/images/logo.png"
            alt="Home"
          >
        </a>
      </div>
    </header>
  </div>
</template>

<script>
    export default {
        name: 'HeaderUSGS'
    }
</script>

<style scoped lang="scss">
  header {
    //display: block;
    width: 100vw;
  }
  .tmp-container {
    margin-right: auto;
    margin-left: auto;
    padding-left: 15px;
    padding-right: 15px;
  }
  .tmp-container a {
    text-decoration: none;
    background: transparent;
  }
  .tmp-container:after {
    clear: both;
  }

  /* header (only) nav */
  .header-nav {
    background: #323333;
;
  }
  .logo-header img {
    margin-top: 5px;
    margin-bottom:0px;
    border: 0;
    height: 55px;
    width: auto;
  }
</style>
