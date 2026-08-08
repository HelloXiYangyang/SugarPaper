import { defineClientConfig } from 'vuepress/client'

import UnderConstruction from "./comps/UnderConstruction.vue";

export default defineClientConfig({
  enhance({ app, router, siteData }) {
    app.component("UnderConstruction", UnderConstruction);
  },
  setup() {},
  rootComponents: [],
})
