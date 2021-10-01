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
      
    },
    computed: {
    },
    mounted(){      
    },
    methods:{
    }
} 
</script>

<style lang="scss">

</style>
