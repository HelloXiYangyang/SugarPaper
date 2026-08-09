<!--
  Copyright (C) 2026 HelloXiYangyang
  SPDX-License-Identifier: GPL-3.0-or-later
-->

<template>
  <v-app>
    <AppTopBar/>
    <v-main>
      <router-view />
    </v-main>
    <AppFooter />
  </v-app>
</template>

<script lang="ts" setup>

import AppTopBar from "./components/AppTopBar.vue";
import AppFooter from "./components/AppFooter.vue";
</script>

<style>

</style>
