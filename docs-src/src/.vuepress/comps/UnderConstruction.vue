<!--
  Copyright (C) 2026 HelloXiYangyang
  SPDX-License-Identifier: CC-BY-NC-SA-4.0
-->

<script setup lang="ts">

</script>

<template>
    <div class="uc-background">
        <img src="../assets/stickers/米沙_欢迎光临.png"
             class="sticker-image" alt="米沙_欢迎光临"
             width="64" height="64"/>
        <div class="uc-content">
  <p><b>糖纸欢迎您参与完善本文档☆Kira~</b></p>
  <p>本章节还在施工中，欢迎正在阅读这个条目的您协助编辑本章节。编辑前请阅读贡献指南，并查找相关资料。糖纸祝您在本文档度过愉快的时光。</p>
        </div>
    </div>
</template>

<style lang="scss" scoped>
.uc-background {
    padding: .25em 1em;
    background-color: var(--vp-c-bg-elv);
    border-radius: 0.5em;
    position: relative;
    overflow: hidden;

    display: flex;
    column-gap: 0.5em;
    margin-block: 0.75em;

    &::before {
        content: '';
        position: absolute;
        left: 0;
        right: 0;
        top: 0;
        bottom: 0;
        background: repeating-linear-gradient(
            45deg,
            rgba(255, 204, 0, 0.1),
            rgba(255, 204, 0, 0.1) 10px,
            rgba(0, 0, 0, 0.1) 10px,
            rgba(0, 0, 0, 0.1) 20px
        );
        mask-image: linear-gradient(to top, rgba(0, 0, 0, 1), rgba(0, 0, 0, 0.4) 0.4em, rgba(0, 0, 0, 0) 1.5em);
        pointer-events: none;
    }
}

.uc-content {
    p {
        line-height: 1.5;
        font-size: var(--hint-font-size);
        margin-block: .5em;
    }
}

.sticker-image {
    max-width: 64px;
    max-height: 64px;
    min-width: 64px;
    min-height: 64px;
    margin-top: .5em;
}
</style>
