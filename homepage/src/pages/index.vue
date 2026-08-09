<!--
  Copyright (C) 2026 HelloXiYangyang
  SPDX-License-Identifier: GPL-3.0-or-later
-->

<template>
  <!-- 主要介绍 -->
  <div class="introduction-container" :class="{ 'intro-enter-active': shouldPlayIntroAnimation }">
    <div class="introduction-bg" />
    <div class="introduction d-flex flex-column margin-x">
      <div class="introduction-col description">
        <div class="brand-home d-flex flex-row flex-wrap intro-seq" style="--intro-delay: 80ms">
          <img src="../assets/logo.svg" width="42" height="42" alt="App Logo" />
          <h1 class="brand-title">糖纸 · SugarPaper</h1>
          <p class="brand-description">作业管理小助手</p>
        </div>
        <div class="feature-main mt-6 intro-seq" style="--intro-delay: 130ms">
          让作业管理像<span class="cyrene">糖果</span>一样甜美简单
        </div>
        <div class="feature-tags mt-3 intro-seq" style="--intro-delay: 180ms">
          <span class="feature-tags-main">功能强 · 可定制 · 跨平台</span>
        </div>
        <div class="feature-tags mt-3 intro-seq" style="--intro-delay: 230ms">
          <span class="opacity-75">秒级录入 · 截止分级 · 番茄专注 · 私有同步</span>
        </div>

        <div class="d-flex ga-2 flex-wrap mt-3 intro-seq" style="--intro-delay: 280ms">
          <a href="https://github.com/HelloXiYangyang/SugarPaper">
            <img src="https://img.shields.io/github/stars/HelloXiYangyang/SugarPaper" alt="Stars" />
          </a>
          <a href="https://github.com/HelloXiYangyang/SugarPaper/blob/main/LICENSE">
            <img src="https://img.shields.io/github/license/HelloXiYangyang/SugarPaper?style=flat-square" alt="开源许可证" />
          </a>
          <a href="https://github.com/HelloXiYangyang/SugarPaper/releases">
            <img src="https://img.shields.io/github/v/release/HelloXiYangyang/SugarPaper?style=flat-square" alt="最新版本" />
          </a>
        </div>
        <div class="d-flex ga-4 flex-wrap mt-8 intro-seq" style="--intro-delay: 330ms">
          <FluentButton to="/download" variant="primary" size="large">
            <template #prepend><FluentSystemIcon name="arrowDownload" /></template>
            立即下载
          </FluentButton>
          <FluentButton
            href="/SugarPaper/app/"
            variant="hyperlink"
            target="_blank"
            size="large"
          >
            <template #prepend><FluentSystemIcon name="documentSparkle" /></template>
            在线使用网页版
          </FluentButton>
          <FluentButton
            href="https://github.com/HelloXiYangyang/SugarPaper"
            variant="hyperlink"
            target="_blank"
            size="large"
          >
            <template #prepend><FluentSystemIcon name="github" /></template>
            GitHub 仓库
          </FluentButton>
        </div>
        <p class="mt-4 platform-requirement intro-seq" style="--intro-delay: 330ms">
          支持在 Android · Web PWA · Windows 上运行，鸿蒙 / 微信小程序规划中。
        </p>
      </div>
    </div>
  </div>

  <div class="content">
    <Subtitle feature-tag="功能强" foreground="linear-gradient(135deg, #01FFFD, #00bdfd)" />

    <div class="margin-x ga-4 d-flex flex-column">
      <FeatureTitle header="直观的信息显示" tag="主界面" color="#01FFFD" />
      <p class="opacity-75">
        打开糖纸，今日作业、完成进度、连胜激励与科目筛选一览无余。已逾期作业自动置顶标红并显示逾期天数，
        今天 / 明天 / 本周 / 长期自动分组，一眼就能看清先做哪件事。
      </p>
      <div class="w-full">
        <v-img src="../assets/screenshots/home-desktop.png" height="90px" alt="主界面演示图">
          <template #placeholder>
            <v-skeleton-loader class="w-full h-full" />
          </template>
        </v-img>
      </div>
    </div>

    <div class="mt-16 d-flex margin-x ga-8 flex-wrap-reverse items-center">
      <div class="flex-grow-2 d-flex" style="flex-basis: 375px">
        <div class="position-relative">
          <!-- 动画演示：把录好的视频放到 homepage/public/demos/reminder-demo.mp4 即可自动播放 -->
          <video
            :src="demoVideoUrl"
            :poster="notesPoster"
            muted
            autoplay
            loop
            width="100%"
            id="notification-demo"
          />
          <div style="position: absolute; bottom: 16px; right: 8px">
            <transition name="fade">
              <FluentButton
                variant="primary"
                id="button_unmute"
                title="取消静音"
                @click="unmute_video"
                v-show="!isVideoSoundRestored"
              >
                <FluentSystemIcon name="speakerMute" class="mt-1" />
              </FluentButton>
            </transition>
          </div>
        </div>
      </div>

      <div
        class="d-flex flex-column ga-4 flex-grow-1"
        style="flex-basis: 375px; container-type: inline-size"
      >
        <FeatureTitle header="醒目的提醒系统" tag="提醒" color="#01FFFD" />
        <p class="opacity-75">
          糖纸可以在作业截止、便签定时等重要时间点发出提醒。除系统通知横幅之外，
          提醒时间可自定义，同一提醒只弹一次，不打扰也不遗漏。
        </p>
        <div class="content-flex-layout">
          <template v-for="feature in notificationFeatures" :key="feature.title">
            <FluentCard
              :title="feature.title"
              :text="feature.description"
              :icon-name="feature.icon"
            >
            </FluentCard>
          </template>
        </div>
      </div>
    </div>

    <div class="d-flex flex-1-1 align-content-center margin-x flex-wrap ga-8 mt-16">
      <div class="d-flex flex-column ga-4 flex-grow-1 flex-wrap" style="flex-basis: 375px">
        <FeatureTitle header="强大的作业管理系统" tag="作业" color="#01FFFD" />
        <p class="opacity-75">
          糖纸具有强大的作业管理系统，可以便捷地录入、编辑和规划作业。
        </p>
        <div class="d-flex flex-column ga-4">
          <FluentCard
            title="截止自动分级"
            icon-name="tagMultiple"
            text="已逾期 / 今天 / 明天 / 本周 / 长期自动分组，逾期置顶标红并显示逾期天数。"
            class="flex-grow-1"
          >
          </FluentCard>
          <FluentCard title="科目筛选与搜索" icon-name="settings" class="flex-grow-1">
            <template #default>
              支持关键词搜索与科目筛选，快速找到某一条作业；点击「完成」自动置底并可撤销。
            </template>
          </FluentCard>
          <FluentCard
            title="日期快捷规划"
            icon-name="clock"
            text="今天 / 明天 / 后天 / 本周内 / 下周 / 长期一键选择，新建作业默认当日。"
            class="flex-grow-1"
          >
          </FluentCard>
        </div>
      </div>
      <div class="flex-grow-2 align-self-center" style="flex-basis: 375px; width: 100%">
        <FluentFlipView :items="screenshots" />
      </div>
    </div>

    <div
      class="margin-x mt-16 align-self-stretch d-flex gc-4 gr-8 justify-center platforms-container flex-column flex-md-row flex-row align-content-start items-start"
    >
      <div class="flex-grow-1 d-flex flex-column gap-4 basis-1/3">
        <FeatureTitle header="秒级录入" tag="录入" color="#01FFFD" />
        <p class="opacity-75">
          粘贴老师发的作业消息自动解析为结构化清单，也支持 .txt / .md 文件导入与中文语音速记。
        </p>
      </div>
      <div class="flex-grow-1 d-flex flex-column gap-4 basis-1/3">
        <FeatureTitle header="拍照存档" tag="存档" color="#01FFFD" />
        <p class="opacity-75">作业可附最多 4 张图片，自动压缩至最长边 512px，仅存本机并随加密快照同步。</p>
      </div>
      <div class="flex-grow-1 d-flex flex-column gap-4 basis-1/3">
        <FeatureTitle header="教师模式" tag="教师" color="#01FFFD" />
        <p class="opacity-75">
          教师模式一键生成标准格式作业文本发到班级群，学生粘贴进糖纸即可秒级导入。
        </p>
      </div>
    </div>

    <div class="d-flex flex-1-1 align-content-start margin-x flex-wrap ga-8 mt-12">
      <div class="flex-grow-1 d-flex flex-column gap-4" style="flex-basis: 375px">
        <FeatureTitle header="日历与统计" tag="日历" color="#01FFFD" />
        <p class="opacity-75">
          月 / 周视图双模式，考试类便签在日期格标记显示，专注分钟以角标呈现；
          统计页提供进度环、柱状、饼图、折线图与准时率、科目欠账排行，一键导出 TXT 或 PNG 报告卡片。
        </p>
        <div class="w-full aspect-video">
          <v-img src="../assets/screenshots/calendar-desktop.png" class="w-full h-full" cover alt="日历演示图">
            <template #placeholder>
              <v-skeleton-loader class="w-full h-full" />
            </template>
          </v-img>
        </div>
      </div>
      <div class="flex-grow-1 d-flex flex-column gap-4" style="flex-basis: 375px">
        <FeatureTitle header="激励体系" tag="激励" color="#01FFFD" />
        <p class="opacity-75">
          完成作业获得 XP，连续打卡累积连胜，12 枚徽章记录每一个里程碑；
          每日目标可自选分段，首页进度条与连胜火焰让每天的进步都看得见。
        </p>
        <div class="w-full aspect-video">
          <v-img
            src="../assets/screenshots/settings-desktop.png"
            class="w-full h-full"
            cover
            alt="激励体系演示图"
          >
            <template #placeholder>
              <v-skeleton-loader class="w-full h-full" />
            </template>
          </v-img>
        </div>
      </div>
    </div>
  </div>

  <div class="content">
    <Subtitle feature-tag="可定制" foreground="var(--cyrene-gradient)" />
    <div class="margin-x d-flex flex-column ga-4">
      <FeatureTitle header="自由的主题系统" tag="主题" color="#EBA2FD" />
      <p class="opacity-75">
        内置七套主题配色，深浅色随意切换；主题化图标配色让底部导航、卡片标题、场景选中与主按钮渐变
        随主题同步换色，界面处处协调统一。
      </p>
      <div class="components-demo-wrap">
        <img
          src="../assets/screenshots/theme-dark.png"
          class="components-demo"
          alt="主题系统演示图"
        />
      </div>
    </div>

    <div class="d-flex flex-1-1 align-content-start margin-x flex-wrap ga-8 mt-12">
      <div class="flex-grow-1 d-flex flex-column gap-4" style="flex-basis: 375px">
        <FeatureTitle header="端到端加密的账号体系" tag="私有同步" color="#EBA2FD" />
        <p class="opacity-75">
          不需要注册，12 词助记词就是你的账号。数据经 AES-256-GCM 端到端加密 + Ed25519 签名后，
          通过 Nostr 中继或 WebRTC 直连同步，中继只能看到密文；网页版、安卓版、Windows 版同一句助记词即可跨端互通。
        </p>
        <div class="w-full aspect-video">
          <v-img
            src="../assets/screenshots/account-modal.png"
            class="w-full h-full"
            cover
            alt="账号体系演示图"
          >
            <template #placeholder>
              <v-skeleton-loader class="w-full h-full" />
            </template>
          </v-img>
        </div>
      </div>
      <div class="flex-grow-1 d-flex flex-column gap-4" style="flex-basis: 375px">
        <FeatureTitle header="好友直连" tag="好友" color="#EBA2FD" />
        <p class="opacity-75">
          生成邀请（含共享密钥）发给好友，对方导入后自动双向确认。消息与作业分享经 AES-256-GCM
          端到端加密后通过 Nostr 中继转发，无中心服务器，只有你们双方能解密。
        </p>
        <div class="w-full">
          <v-img
            src="../assets/screenshots/theme-bluegreen.png"
            class="w-full h-full"
            cover
            alt="好友直连演示图"
          >
            <template #placeholder>
              <v-skeleton-loader class="w-full h-full" />
            </template>
          </v-img>
        </div>
      </div>
    </div>

    <div
      class="d-flex flex-1-1 align-content-center items-center margin-x flex-wrap flex-md-nowrap ga-8 mt-16"
    >
      <div class="d-flex flex-column ga-4 flex-grow-1 flex-md-grow-0 flex-wrap basis-1/4">
        <FeatureTitle header="零服务器发布生态" tag="发布" color="#EBA2FD" />
        <p class="opacity-75">
          糖纸的官网、网页版、安装包与自动更新全部基于 GitHub 免费能力运行，不依赖任何云服务器。
        </p>
        <p class="opacity-75">
          完整方案见<a
            href="https://github.com/HelloXiYangyang/SugarPaper/blob/main/🧁%20糖纸%20·%20SugarPaper%20——%20零服务器多平台发布·自动更新·官网方案%20v2.0.md"
            target="_blank"
            >《零服务器多平台发布 · 自动更新 · 官网方案 v2.0》</a
          >。
        </p>
      </div>
      <div class="align-self-center basis-3/4 flex-grow-1 flex-md-grow-0" style="">
        <div class="plugins-grid-fade">
          <div class="plugins-grid">
            <PluginCard
              v-for="plugin in plugins"
              :title="plugin.title"
              :url="plugin.url"
              :icon="plugin.icon"
              :description="plugin.description"
              class="plugins-grid-item"
            />
          </div>
        </div>
      </div>
    </div>
  </div>
  <div class="content">
    <Subtitle feature-tag="跨平台" foreground="linear-gradient(135deg, #ffb802, #ffb802)" />

    <div class="mt-16 d-flex flex-1-1 margin-x ga-8 flex-wrap-reverse flex-md-nowrap items-center">
      <div class="d-flex basis-3/4 flex-grow-1" style="flex-basis: 375px">
        <FluentFlipView :items="screenshotsPlatforms" />
      </div>
      <div
        class="d-flex flex-column ga-4 flex-grow-1 flex-md-grow-0 flex-wrap basis-1/4"
        style="flex-basis: 375px"
      >
        <FeatureTitle header="优秀的多平台兼容性" tag="多端支持" color="#ffb802" />
        <p class="opacity-75">
          同一套代码与数据模型，网页版、安卓版与 Windows 桌面版功能完全对齐；
          同一句助记词即可跨端互通，Android 5.0+ 兼容并按系统版本分级开放功能。
        </p>
      </div>
    </div>
  </div>

  <div class="content">
    <h2 class="headline-feature text-center">除了这些…</h2>

    <div
      class="d-flex flex-1-1 align-content-center items-center margin-x flex-wrap flex-md-nowrap ga-8 mt-16"
    >
      <div
        class="d-flex flex-column ga-4 flex-grow-1 flex-md-grow-0 basis-1/4 flex-wrap"
        style="flex-basis: 375px"
      >
        <FeatureTitle header="手把手的快速上手教程" tag="教程" color="#66ccff" />
        <p class="opacity-75">
          文档站提供从「粘贴第一条作业」到「跨端同步」的图文教程，下载安装、创建账号、秒级录入一步到位。
        </p>
        <div>
          <FluentButton href="/SugarPaper/docs/get-started/" variant="hyperlink" target="_blank">
            <template #prepend><FluentSystemIcon name="bookOpen" /></template>
            前往快速上手
          </FluentButton>
        </div>
      </div>
      <div class="align-self-center basis-3/4 flex-grow-1" style="flex-basis: 375px; width: 100%">
        <div class="w-full aspect-video">
          <v-img
            src="../assets/screenshots/import-modal.png"
            class="w-full h-full"
            cover
            alt="快速上手演示图"
          >
            <template #placeholder>
              <v-skeleton-loader class="w-full h-full" />
            </template>
          </v-img>
        </div>
      </div>
    </div>

    <div class="d-flex flex-1-1 align-content-center margin-x flex-wrap ga-8 mt-16">
      <div class="d-flex flex-column ga-4 flex-grow-1 flex-wrap">
        <FeatureTitle header="可靠的运行保障" tag="可靠" color="#FF7900" />
        <p class="opacity-75">
          糖纸在设计时充分考虑了学生维护时间不足、数据安全敏感的情况，
          离线优先、数据只存本机，同步全程端到端加密。
        </p>

        <div class="d-flex ga-4 flex-wrap">
          <FluentCard
            title="离线优先"
            icon-name="codeText"
            text="所有核心功能离线可用，数据默认只存本机，断网也能正常使用。"
            class="feature-card-divided"
          >
          </FluentCard>
          <FluentCard
            title="自动更新校验"
            icon-name="checkmarkCircle"
            text="客户端读取元数据比较 build 号，流式下载后校验 SHA-256 再交给系统安装器。"
            class="feature-card-divided"
          >
          </FluentCard>
          <FluentCard
            title="备份与恢复"
            icon-name="archive"
            text="支持导出 JSON 备份；同一句助记词在任意设备登录即可恢复全部数据。"
            class="feature-card-divided"
          >
          </FluentCard>
          <FluentCard
            title="隐私保护"
            icon-name="lockClosed"
            text="账号等于本地密钥，不做自建服务器，Nostr 中继只能看到密文。"
            class="feature-card-divided"
          >
          </FluentCard>
        </div>
      </div>
    </div>
  </div>

  <div class="content align-content-center items-center margin-x d-flex flex-col">
    <h2 class="headline-feature text-center">社区认可</h2>

    <span class="text-center opacity-75">感谢每一位使用、反馈与贡献的同学。</span>

    <div class="d-flex align-center align-conent-center mt-4 ga-2 flex-wrap justify-center">
      <a href="https://github.com/HelloXiYangyang/SugarPaper" target="_blank"
        ><img
          src="https://img.shields.io/github/stars/HelloXiYangyang/SugarPaper"
          alt="GitHub Stars"
          style="height: 24px"
      /></a>
      <a href="https://github.com/HelloXiYangyang/SugarPaper/network" target="_blank"
        ><img
          src="https://img.shields.io/github/forks/HelloXiYangyang/SugarPaper?style=flat-square"
          alt="GitHub Forks"
          style="height: 24px"
      /></a>
      <a href="https://github.com/HelloXiYangyang/SugarPaper/blob/main/LICENSE" target="_blank"
        ><img
          src="https://img.shields.io/github/license/HelloXiYangyang/SugarPaper?style=flat-square"
          alt="开源许可证"
          style="height: 24px"
      /></a>
      <a href="https://github.com/HelloXiYangyang/SugarPaper/commits/main" target="_blank"
        ><img
          src="https://img.shields.io/github/last-commit/HelloXiYangyang/SugarPaper?style=flat-square"
          alt="最近提交"
          style="height: 24px"
      /></a>
      <a href="https://github.com/HelloXiYangyang/SugarPaper/releases" target="_blank"
        ><img
          src="https://img.shields.io/github/v/release/HelloXiYangyang/SugarPaper?style=flat-square"
          alt="最新版本"
          style="height: 24px"
      /></a>
    </div>
  </div>

  <div class="content d-flex flex-column ga-8 margin-x">
    <span class="text-h5 align-self-center">更多功能留给您自行探索！</span>
    <div class="d-flex flex-row ga-2 align-self-center">
      <FluentButton variant="primary" to="/download">
        <template #prepend><FluentSystemIcon name="arrowDownload" /></template>
        立即下载 SugarPaper
      </FluentButton>
      <FluentButton href="https://github.com/HelloXiYangyang/SugarPaper" target="_blank">
        <template #prepend><FluentSystemIcon name="github" /></template>
        了解更多
      </FluentButton>
    </div>
  </div>
</template>

<style scoped>
h1 {
  font-size: 64px;
  font-weight: 500;
}

.content-flex-layout {
  display: flex;
  @container (max-width: 632px) {
    flex-wrap: wrap;
  }
  gap: 16px;
}

.content-flex-layout > * {
  flex-grow: 1;
  flex-basis: 200px;
}

.plugins-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 8px;
}

.plugins-grid-fade {
  position: relative;
}

.plugins-grid-fade::after {
  content: '';
  position: absolute;
  left: 0;
  right: 0;
  bottom: 0;
  height: 160px;
  pointer-events: none;
  background-color: var(--background-fill-color-solid-background-base, #fff);
  -webkit-mask-image: linear-gradient(to bottom, transparent, #000);
  mask-image: linear-gradient(to bottom, transparent, #000);
}

.plugins-grid > :deep(.plugin-card-link) {
  width: 100%;
  max-width: none;
  flex-basis: auto;
}

.content {
  padding-top: 42px;
  padding-bottom: 42px;
}

.components-demo-wrap {
  width: 100vw;
  width: 100dvw;
  margin-top: 32px;
  margin-left: calc(50% - 50vw);
  margin-left: calc(50% - 50dvw);
  overflow: hidden;
}

.components-demo {
  display: block;
  width: 100%;
  height: clamp(220px, 20vw, 520px);
  object-fit: cover;
  object-position: center;
}

.introduction-container {
  position: relative;
  overflow: hidden;
}

.introduction {
  width: 100%;
  position: relative;
  z-index: 1;
  display: flex;
  flex-direction: row;
  justify-content: space-between;
  align-items: start;
  padding-right: clamp(160px, 24vw, 440px);

  @media (max-width: 1000px) {
    padding-right: clamp(56px, 12vw, 120px);

    .img-col {
      display: none;
    }
  }

  @media (max-width: 675px) {
    padding-right: 0;
  }

  .img-col {
    flex-basis: 0;
    flex-shrink: 1;
    margin-right: -200px;
  }
  .description {
    margin-top: 10vh;
  }

  @media (min-width: 1000px) {
    .img-position-absolute {
      position: absolute;
    }
    .desktop-img {
      transition: all 0.8s cubic-bezier(0.08, 0.82, 0.17, 1) 0.1s;
      height: 75vh;
      margin-top: 10vh;
      margin-right: -30vw;
    }

    .desktop-img:hover {
      transform: translateX(-15vw);
    }
  }
}

.brand-home {
  display: flex;
  flex-direction: row;
  align-items: center;
  align-self: start;
  column-gap: 16px;
  row-gap: 8px;
}

.app-logo {
  width: 96px;
  height: 96px;
}

.introduction-col {
  min-width: min(400px, 100%);
  max-width: 100%;
  flex-basis: 480px;
}

.intro-enter-active .intro-seq {
  @apply motion-safe:animate-[introColFadeInLeft_.72s_cubic-bezier(0.16,1,0.3,1)_both];
  animation-delay: var(--intro-delay, 0ms);
}

.brand-title {
  font-size: 36px;

  @media (max-width: 675px) {
    font-size: 36px;
  }

  font-weight: 600;
}

.headline-feature {
  font-size: 42px;
  font-weight: 600;
  margin-bottom: 20px;
}

@keyframes labelSlideOut {
  0% {
    -webkit-transform: translateY(0);
    transform: translateY(0);
    opacity: 100%;
  }

  100% {
    -webkit-transform: translateY(-100%);
    transform: translateY(-100%);
    opacity: 0;
  }
}

@keyframes labelSlideIn {
  0% {
    -webkit-transform: translateY(100%);
    transform: translateY(100%);
    opacity: 0;
  }

  100% {
    -webkit-transform: translateY(0);
    transform: translateY(0);
    opacity: 100%;
  }
}

.feature-pill {
  font-size: 42px;
  font-weight: bold;
}

.feature-main {
  font-size: 48px;
  line-height: 54px;
  font-weight: bold;
}

.feature-tags {
  font-size: 24px;
  font-weight: 500;
  line-height: 32px;
  .feature-tags-main {
    font-size: 32px;
  }
}

.introduction-container {
  background: radial-gradient(44.58% 35.38% at 78.87% 75.56%, #0c0e1f 0%, rgba(12, 14, 31, 0) 100%),
    radial-gradient(76.32% 55.47% at -4.1% 9.31%, #0c0e1f 0%, rgba(12, 14, 31, 0) 100%), #0d1111;
}
.introduction-bg {
  position: absolute;
  top: 0;
  right: 0;
  bottom: 0;
  width: clamp(620px, 88vw, 1600px);
  z-index: 0;
  pointer-events: none;
  background-position:
    left center,
    right center;
  background-image: linear-gradient(
      90deg,
      rgba(13, 17, 17, 1) 0%,
      rgba(13, 17, 17, 1) 5%,
      rgba(13, 17, 17, 0.8) 22%,
      rgba(13, 17, 17, 0.4) 32%,
      rgba(13, 17, 17, 0) 58%,
      rgba(13, 17, 17, 0) 100%
    ),
    url('../assets/screenshots/home-dark.png');
  background-repeat: no-repeat;
  background-size:
    100% 100%,
    100% auto;

  @media (max-width: 1200px) {
    width: clamp(520px, 84vw, 1120px);
    background-size:
      100% 100%,
      100% auto;
  }

  @media (max-width: 1000px) {
    width: clamp(420px, 92vw, 920px);
    background-image: linear-gradient(
        90deg,
        rgba(13, 17, 17, 1) 0%,
        rgba(13, 17, 17, 1) 5%,
        rgba(13, 17, 17, 0.9) 20%,
        rgba(13, 17, 17, 0.7) 42%,
        rgba(13, 17, 17, 0.25) 78%,
        rgba(13, 17, 17, 0) 100%
      ),
      url('../assets/screenshots/home-dark.png');
    background-position:
      left center,
      right bottom;
    background-size:
      100% 100%,
      100% auto;
  }

  @media (max-width: 675px) {
    width: clamp(360px, 120vw, 760px);
    background-image: linear-gradient(
        90deg,
        rgba(13, 17, 17, 1) 0%,
        rgba(13, 17, 17, 1) 5%,
        rgba(13, 17, 17, 0.8) 20%,
        rgba(13, 17, 17, 0.7) 32%,
        rgba(13, 17, 17, 0.6) 78%,
        rgba(13, 17, 17, 0) 100%
      ),
      url('../assets/screenshots/home-dark.png');
    background-position:
      left center,
      right 85%;
    background-size:
      100% 100%,
      100% auto;
  }
}

.intro-enter-active .introduction-bg {
  @apply motion-safe:[transform-origin:right_center] motion-safe:[will-change:transform,opacity] motion-safe:animate-[introBgFlyInRightExpand_0.75s_cubic-bezier(0.16,1,0.3,1)_60ms_both];
}

@keyframes introColFadeInLeft {
  0% {
    opacity: 0;
    transform: translate3d(-42px, 0, 0);
  }

  100% {
    opacity: 1;
    transform: translate3d(0, 0, 0);
  }
}

@keyframes introBgFlyInRightExpand {
  0% {
    opacity: 0;
    transform: translate3d(96px, 0, 0) scale(0.86);
  }
  100% {
    opacity: 1;
    transform: translate3d(0, 0, 0) scale(1);
  }
}

.feature-card-divided {
  flex-basis: 480px;
  flex-grow: 1;
}

@keyframes content-in {
  from {
    opacity: 0;
    transform: translateY(100%);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.cyrene {
  background-image: var(--cyrene-gradient);
  background-clip: text;
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
}

.brand-description {
  font-size: 20px;
}

.platform-requirement {
  font-size: 13px;
  /* opacity: 0.75; */
}
</style>

<script lang="ts" setup>
import { gsap } from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';
import IFeature from '../interfaces/IFeature';
import { nextTick, onBeforeUnmount, onMounted, ref } from 'vue';
import { useRouter } from 'vue-router';
import PluginCard from '../components/PluginCard.vue';

import { useHead } from '@unhead/vue';
import FluentButton from '../components/fluent/FluentButton.vue';
import FluentCard from '../components/fluent/FluentCard.vue';
import FluentFlipView from '../components/fluent/FluentFlipView.vue';
import FluentSystemIcon from '../components/FluentSystemIcon.vue';

import homeDesktop from '../assets/screenshots/home-desktop.png';
import homeMobile from '../assets/screenshots/home-mobile.png';
import focusWide from '../assets/screenshots/focus-page-wide.png';
import calendarDesktop from '../assets/screenshots/calendar-desktop.png';
import statsDesktop from '../assets/screenshots/stats-desktop.png';
import notesPoster from '../assets/screenshots/notes-desktop.png';
import Subtitle from '../components/Subtitle.vue';
import FeatureTitle from '../components/FeatureTitle.vue';
import IPluginInfo from '../interfaces/IPluginInfo';

const screenshots = [homeDesktop, calendarDesktop, statsDesktop];
const screenshotsPlatforms = [homeMobile, homeDesktop, focusWide];
const demoVideoUrl = import.meta.env.BASE_URL + 'demos/reminder-demo.mp4';

useHead({
  title: '糖纸 · SugarPaper — 一款功能强、可定制、跨平台的作业管理小助手',
  meta: [
    {
      name: 'description',
      content:
        '糖纸 · SugarPaper 是一款离线优先的跨平台作业管理小助手：秒级录入、截止分级、番茄专注、白噪音、便签提醒、日历统计、激励体系、好友直连与端到端加密同步。'
    }
  ]
});

const router = useRouter();
let scrollRevealContext: gsap.Context | null = null;
let introAnimationTimeout: ReturnType<typeof setTimeout> | null = null;
let scrollTriggerRefreshFrame: number | null = null;
let scrollTriggerResizeObserver: ResizeObserver | null = null;
let scrollTriggerLoadHandler: (() => void) | null = null;

const shouldPlayIntroAnimation = ref(false);

function unmute_video(event: Event) {
  const video = document.getElementById('notification-demo') as HTMLVideoElement;
  isVideoSoundRestored.value = true;
  video.muted = false;
}

function gotoDownload() {
  router.push('/download');
}

const isVideoSoundRestored = ref(false);

function scheduleScrollTriggerRefresh() {
  if (scrollTriggerRefreshFrame !== null) {
    cancelAnimationFrame(scrollTriggerRefreshFrame);
  }

  scrollTriggerRefreshFrame = requestAnimationFrame(() => {
    scrollTriggerRefreshFrame = null;
    ScrollTrigger.refresh();
  });
}

const notificationFeatures: Array<IFeature> = [
  {
    title: '横幅通知',
    icon: 'alertBadge',
    description: '作业截止、便签到点弹出系统通知横幅'
  },
  {
    title: '定时提醒',
    icon: 'clock',
    description: '前一晚与当天早上提醒时间可自定义'
  },
  {
    title: '单次提醒',
    icon: 'checkmarkCircle',
    description: '同一提醒只弹一次，不打扰也不遗漏'
  },
  {
    title: '声音提醒',
    icon: 'speaker2',
    description: '随系统通知音效，静音模式也可靠'
  }
];

const plugins: Array<IPluginInfo> = [
  {
    title: 'GitHub Releases',
    icon: 'https://cdn.simpleicons.org/github/white',
    description: '安装包托管在 GitHub Releases，官网按钮自动指向最新版本。',
    url: 'https://github.com/HelloXiYangyang/SugarPaper/releases'
  },
  {
    title: 'GitHub Pages',
    icon: 'https://cdn.simpleicons.org/git/white',
    description: '官网、网页版与更新元数据全部零服务器托管。',
    url: 'https://helloxiyangyang.github.io/SugarPaper/'
  },
  {
    title: 'GitHub Actions',
    icon: 'https://cdn.simpleicons.org/githubactions/white',
    description: '推送标签自动构建安装包、计算 SHA-256 并回写元数据。',
    url: 'https://github.com/HelloXiYangyang/SugarPaper/actions'
  },
  {
    title: '方案文档',
    icon: 'https://cdn.simpleicons.org/markdown/white',
    description: '《零服务器多平台发布 · 自动更新 · 官网方案 v2.0》。',
    url: 'https://github.com/HelloXiYangyang/SugarPaper/blob/main/🧁%20糖纸%20·%20SugarPaper%20——%20零服务器多平台发布·自动更新·官网方案%20v2.0.md'
  }
];

onMounted(() => {
  const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  if (!prefersReducedMotion) {
    requestAnimationFrame(() => {
      shouldPlayIntroAnimation.value = true;
      introAnimationTimeout = setTimeout(() => {
        shouldPlayIntroAnimation.value = false;
        introAnimationTimeout = null;
      }, 1400);
    });
  }

  if (prefersReducedMotion) {
    return;
  }

  gsap.registerPlugin(ScrollTrigger);
  scrollRevealContext = gsap.context(() => {
    const contentBlocks = gsap.utils.toArray<HTMLElement>('.content > *');
    contentBlocks.forEach((block) => {
      ScrollTrigger.create({
        trigger: block,
        start: 'top 88%',
        once: true,
        onEnter: () => {
          gsap.fromTo(
            block,
            { y: 50, opacity: 0 },
            {
              y: 0,
              opacity: 1,
              duration: 0.8,
              ease: 'power2.out',
              clearProps: 'transform,opacity'
            }
          );
        }
      });
    });
  });

  nextTick(() => {
    scheduleScrollTriggerRefresh();

    if ('ResizeObserver' in window) {
      scrollTriggerResizeObserver = new ResizeObserver(scheduleScrollTriggerRefresh);
      scrollTriggerResizeObserver.observe(document.body);
    }
  });

  scrollTriggerLoadHandler = scheduleScrollTriggerRefresh;
  if (document.readyState === 'complete') {
    scheduleScrollTriggerRefresh();
  } else {
    window.addEventListener('load', scrollTriggerLoadHandler, { once: true });
  }
});

onBeforeUnmount(() => {
  if (introAnimationTimeout) {
    clearTimeout(introAnimationTimeout);
    introAnimationTimeout = null;
  }

  if (scrollTriggerRefreshFrame !== null) {
    cancelAnimationFrame(scrollTriggerRefreshFrame);
    scrollTriggerRefreshFrame = null;
  }

  if (scrollTriggerLoadHandler) {
    window.removeEventListener('load', scrollTriggerLoadHandler);
    scrollTriggerLoadHandler = null;
  }

  scrollTriggerResizeObserver?.disconnect();
  scrollTriggerResizeObserver = null;

  scrollRevealContext?.revert();
  scrollRevealContext = null;
});
</script>
