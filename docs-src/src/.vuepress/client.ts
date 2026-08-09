/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: CC-BY-NC-SA-4.0
 */

import { defineClientConfig } from 'vuepress/client'

import UnderConstruction from "./comps/UnderConstruction.vue";

export default defineClientConfig({
  enhance({ app, router, siteData }) {
    app.component("UnderConstruction", UnderConstruction);
  },
  setup() {},
  rootComponents: [],
})
