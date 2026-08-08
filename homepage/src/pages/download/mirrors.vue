<script setup lang="ts">
import { useHead } from '@unhead/vue';

useHead({
  title: '下载镜像 | 糖纸 · SugarPaper',
  meta: [
    {
      name: 'description',
      content:
        '糖纸 · SugarPaper 是一款离线优先的跨平台作业管理小助手。如果您在通过 GitHub 下载时遇到问题，可以从此处的镜像下载。'
    }
  ]
});
</script>

<template>
  <div class="margin-x flex-col ga-4 d-flex mt-6">
    <h1 class="text-h4">下载镜像</h1>
    <p>如果您在通过 GitHub 下载糖纸时遇到问题，可以从以下镜像下载（请核对 SHA-256 后再安装）。</p>
    <ul class="list-disc">
      <li>
        <a href="https://github.com/HelloXiYangyang/SugarPaper/releases" target="_blank" rel="noopener">GitHub Releases（官方）</a>
      </li>
      <li>
        <a href="https://cdn.jsdelivr.net/gh/HelloXiYangyang/SugarPaper@main/updates/latest.json" target="_blank" rel="noopener">jsDelivr CDN（元数据缓存）</a>
      </li>
      <li>
        <a href="https://ghproxy.com/" target="_blank" rel="noopener">ghproxy 类代理（下载加速，第三方）</a>
      </li>
    </ul>
    <p class="opacity-75" style="font-size: 13px">
      建议优先使用官网按钮下载；应用内更新会先校验 SHA-256 再安装，请勿从未知来源获取安装包。
    </p>
  </div>
</template>

<style scoped lang="scss">
ul li::marker {
  margin-left: 16px;
}
</style>
