<template>
  <div class="maxWidth carouselContainer">
    <carousel
      class="image-slider"
      :autoplay="true"
      :autoplay-hover-pause="true"
      :per-page="4"
    >
      <slide class="slide">
        <div class="slider-image-container">
          <picture>
            <source
              srcset="@/assets/methods/SAMPLE.webp"
              type="image/webp"
            >
            <source
              srcset="@/assets/methods/SAMPLE.jpg"
              type="image/jpg"
            >
            <img 
              id="field1"
              v-img="{
                thumbnails: true,
                group: 'group', 
                title: ''
              }"
              class="sliderImage"
              src="@/assets/methods/SAMPLE.jpg"
              alt=""
              loading="lazy"
            >
          </picture>
        </div>
      </slide>
    </carousel>
  </div>
</template>

<script>
    import { Carousel, Slide } from 'vue-carousel';

    export default {
        name: 'ImgCarousel',
        components:{
            Carousel,
            Slide
        }
    }
</script>

<style scoped lang="scss">
  .image-slider {
    *:focus{
      outline: none;
    }
  }
  .slide {
    margin: 0;
    padding: 0;
    select:focus{
      outline: none;
    }
  }
  .slider-image-container {
    padding: 10px;
    display: block;
    height: 400px;
    width: auto;
    object-fit: contain;
    img {
      height: 400px; 
      width: auto;
    }
  }
</style>