<!--
  Copyright (C) 2026 HelloXiYangyang
  SPDX-License-Identifier: GPL-3.0-or-later
-->

<script setup lang="ts">
const props = defineProps({
  header: String,
  tag: String,
  color: String
})
</script>

<template>
<div>
  <p class="font-medium mb-1" :style="`color: ${props.color}`">#{{ props.tag }}</p>
  <h3 class="font-bold text-3xl">{{ props.header }}</h3>
</div>
</template>

<style scoped lang="scss">

</style>
