<template>
  <div id="visualization">
    <GWL />
  </div>
</template>

<script>

export default {
    name: 'Visualization',
    components: {
      GWL: () => import( /* webpackPreload: true */ /*webpackChunkName: "section"*/ "./../components/GWL")
      //DA: () => import( /* webpackPreload: true */ /*webpackChunkName: "section"*/ "./../components/DA")

    },
    computed: {
    },
    mounted(){
      const self = this;
      
    },
    methods:{
    }
} 
</script>

<style lang="scss">

</style>
