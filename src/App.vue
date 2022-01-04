<template>
  <div id="app">
    <!--  <HeaderUSWDSBanner /> -->
    <HeaderUSGS />
    <InternetExplorerPage v-if="isInternetExplorer" />
    <!-- an empty string in this case means the 'prod' version of the application   -->
    <router-view
      v-if="!isInternetExplorer"
    />
    <PreFooterCodeLinks v-if="!isInternetExplorer" />
    <FooterUSGS />
  </div>
</template>

<script>
    import HeaderUSGS from './components/HeaderUSGS';
    import { isMobile } from 'mobile-device-detect';
    export default {
        name: 'App',
        components: {
            HeaderUSGS,
            InternetExplorerPage: () => import( /* webpackPrefetch: true */ /*webpackChunkName: "internet-explorer-page"*/ "./components/InternetExplorerPage"),
            //HeaderUSWDSBanner: () => import( /* webpackPrefetch: true */ /*webpackChunkName: "header-uswds-banner"*/ "./components/HeaderUSWDSBanner"),
            //PreFooterVisualizationsLinks: () => import( /* webpackPrefetch: true */ /*webpackChunkName: "pre-footer-links-visualizations"*/ "./components/PreFooterVisualizationsLinks"),
            PreFooterCodeLinks: () => import( /* webpackPrefetch: true */ /*webpackChunkName: "pre-footer-links-code"*/ "./components/PreFooterCodeLinks"),
            FooterUSGS: () => import( /* webpackPrefetch: true */ /*webpackChunkName: "usgs-footer"*/ "./components/FooterUSGS") // Have Webpack put the footer in a separate chunk so we can load it conditionally (with a v-if) if we desire
        },
        data() {
            return {
                isInternetExplorer: false,
                title: process.env.VUE_APP_TITLE,
                publicPath: process.env.BASE_URL, // this is need for the data files in the public folder
                mobileView: isMobile
            }
        },
        computed: {
          checkTypeOfEnv() {
              return process.env.VUE_APP_TIER
          }
        },
        created() {
            // We are ending support for Internet Explorer, so let's test to see if the browser used is IE.
            this.$browserDetect.isIE ? this.isInternetExplorer = true : this.isInternetExplorer = false;
            // Add window size tracking by adding a listener and a way to store the values in the Vuex state
            window.addEventListener('resize', this.handleResize);
            this.handleResize();
        },
        destroyed() {
            window.removeEventListener('resize', this.handleResize);
        },
        methods:{
          handleResize() {
                this.$store.commit('recordWindowWidth', window.innerWidth);
                this.$store.commit('recordWindowHeight', window.innerHeight);
            },
        }
    }
</script>

<style lang="scss">
// Fonts
@import url('https://fonts.googleapis.com/css2?family=Assistant:wght@200;300;400;500;600;700;800&display=swap');
@import url('https://fonts.googleapis.com/css2?family=Open+Sans:ital,wght@0,300;0,400;0,500;0,600;0,700;0,800;1,300;1,400;1,500;1,600;1,700;1,800&display=swap');

$Assistant: 'Assistant', sans-serif;
$open_sans: 'Open Sans', sans-serif;

html,
body {
      height:100%;
      background-color: rgb(223, 223, 223);
      margin: 0;
      padding: 0;
      line-height: 1.2;
      font-size: 20px;
      font-weight: 300;
      -webkit-font-smoothing: antialiased;
      -moz-osx-font-smoothing: grayscale;
      width: 100%;
      @media screen and (max-width: 800px) {
        //font-size: 16px;
      }
  }
  h1, h2, h3, h4 {
    line-height: 1;
    text-align: left;
    font-family: $Assistant;
    font-weight: 600;
    margin: 0 0;
  }
h1{
  font-size: 3.5em;
  @media screen and (max-width: 600px) {
    font-size: 2.5em;
  }
}
h2{
  font-size: 2.8em;
  @media screen and (max-width: 800px) {
        font-size: 2.3rem;
      }
  @media screen and (max-width: 650px) {
    font-size: 1.3em;
  }
}
h3{
  font-size: 1.5em;
  //padding-top: 0.5em;
  @media screen and (max-width: 800px) {
      font-size: 1.3em;
  }  
  @media screen and (max-width: 650px) {
      font-size: 1em;
  }  
}
h4{
  font-size: 1.2em;
  padding-top: 0em;
  font-weight: 600;
  @media screen and (max-width: 800px) {
      font-size: 1em;
  }  
  @media screen and (max-width: 650px) {
      font-size: 1em;
  }  
}
p, text, caption {
  padding: 0.5em 0 0 0; 
  font-family: $Assistant;
  font-weight: 400;
  line-height: 1.3;
  margin: 0px 0px;
  @media screen and (max-width: 800px) {
        font-size: 16px;
      }
}
caption {
  padding: 0;
  font-style: italic;
  font-size: 0.8rem;
  display: block;
  width: 100%;
  max-width: 700px;
}
// make svg text smaller than main text at small viewport sizes so it fits on the screen
text {
  //font-size: 20px;
  @media screen and (max-width: 800px) {
        font-size: 16px;
      }
  @media screen and (max-width: 550px) {
        font-size: 13px;
      }
   }
// legend text is scaled differently because the svg has a max-width property set 
.legend-text {
 /*  font-size: 16px;
  @media screen and (max-width: 800px) {
        font-size: 20px;
      } */
    @media screen and (max-width: 550px) {
        font-size: 20px;
      }
}

</style>
