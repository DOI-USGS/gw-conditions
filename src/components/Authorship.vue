<template>
  <div id="author-container" v-if="showAuthors">
    <p>
      <span id="primary-author-statment">
        The development of {{ appTitle }} was led by 
        <span
          v-for="(author, index) in primaryAuthors" 
          :key="`${author.initials}-attribution`"
          :id="`initial-${author.initials}`"
          :class="'author first'"
        >
          <a v-bind:href="author.profile_link" target="_blank" v-text="author.fullName"></a>
          <span v-if="index != Object.keys(primaryAuthors).length - 1 && Object.keys(primaryAuthors).length > 2">, </span>
          <span v-if="index == Object.keys(primaryAuthors).length - 2"> and </span>
        </span>.
      </span>
      <span id="additional-author-statement" v-if="showAdditionalAuthors">
        <span
          v-for="(author, index) in additionalAuthors" 
          :key="`${author.initials}-attribution`"
          :id="`author-${author.initials}`"
          :class="'author'"
        >
          <a v-bind:href="author.profile_link" target="_blank" v-text="author.fullName"></a>
          <span v-if="index != Object.keys(additionalAuthors).length - 1 && Object.keys(additionalAuthors).length > 2">, </span>
          <span v-if="index == Object.keys(additionalAuthors).length - 2"> and </span>
        </span>
        <span>
        also contributed to the site.
        </span>
      </span>
      <span id="contribution-statements" v-if="showContributionStatements">
        <span id="primary-author-contribution">
          <span
            v-for="author in primaryAuthors" 
            :key="`${author.initials}-contribution`"
            :id="`author-${author.initials}`"
            :class="'author'"
          >
            <span v-text="author.firstName"> </span> <span v-text="author.contribution"></span>. 
          </span>
        </span>
        <span id="additional-author-contribution"  v-if="showAditionalContributionStatement">
          <span
            v-for="author in additionalAuthors" 
            :key="`${author.initials}-contribution`"
            :id="`author-${author.initials}`"
            :class="'author'"
          >
            <span v-text="author.firstName"> </span> <span v-text="author.contribution"></span>. 
          </span>
        </span>
      </span>
    </p>
  </div>
</template>

<script>
import { isMobile } from 'mobile-device-detect';
import authors from "@/assets/text/authors";
export default {
  name: "authorship",
    components: {
    },
    props: {
    },
    data() {
      return {
        publicPath: process.env.BASE_URL, // allows the application to find the files when on different deployment roots
        appTitle: process.env.VUE_APP_TITLE, // Pull in title of page from Vue environment (set in .env)
        mobileView: isMobile, // test for mobile
        primaryAuthors: authors.primaryAuthors,
        additionalAuthors: authors.additionalAuthors,
        showAuthors: null, // Turn on or off attribution for all authors
        showAdditionalAuthors: null, // If showAuthors is true, turn on or off attribution for additional authors
        showContributionStatements: true, // If showAuthors is true, turn on or off contribution statements for ALL authors
        showAditionalContributionStatement: null // If showAuthors is true and if showContributionStatements is true, turn on or off contriubtion statements for ADDITIONAL authors
      }
    },
    mounted(){   
      console.log(this.appTitle)
      this.showAuthors = this.primaryAuthors.length > 0 ? true: false; // Show author statements for any authors
      this.showAdditionalAuthors =  this.additionalAuthors.length > 0 ? true : false; // Show author statements for additional authors if any are listed
      this.showAditionalContributionStatement = this.additionalAuthors.length > 0 ? true : false; // Show contributions statements for additional authors if any are listed AND showContributionStatements is true
    },
    methods:{
      isMobile() {
              if(/Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent)) {
                  return true
              } else {
                  return false
              }
          }
    }
}
</script>
<style>
#author-container {
  height: auto;
}
</style>