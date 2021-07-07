<template>
  <div id="code-repository-link-container">
    <a
      :href="gitHubRepositoryLink"
      target="_blank"
      aria-label="github link"
    >See the code behind this visualization
      <font-awesome-icon :icon="{ prefix: 'fab', iconName: 'github' }" />
    </a>
  </div>
</template>

<script>
  export default {
      name: 'PreFooterCodeLinks',
      data() {
          return {
              gitHubRepositoryLink: process.env.VUE_APP_GITHUB_REPOSITORY_LINK,
              projectTitle: process.env.VUE_APP_TITLE
          }
      }
  }

</script>

<style lang="scss">

  #code-repository-link-container {
    display: flex;
    justify-content: right;
    width: 100%;
    background-color: #c2c4c5;
    margin: 0 auto;
    padding: 0.4rem;
    border-bottom: 2px solid black;
    a {
      color: #090211;
      margin-left: 10px;
      font-family: 'Source Sans Pro',sans-serif;
      text-decoration: none
    }
  }

</style>
