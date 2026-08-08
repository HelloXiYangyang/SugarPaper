<script setup lang="ts">
import { onMounted, ref, computed } from 'vue';
import DownloadPlatformCard from '../../../components/DownloadPlatformCard.vue';
import SplitDownloadButton from '../../../components/SplitDownloadButton.vue';
import FluentButton from '../../../components/fluent/FluentButton.vue';
import FluentDialog from '../../../components/fluent/FluentDialog.vue';
import FluentSystemIcon from '../../../components/FluentSystemIcon.vue';
import { useHead } from '@unhead/vue';

const isLoading = ref(true);
const isError = ref(false);
const version = ref('');
const androidUrl = ref('');
const windowsUrl = ref('');
const webUrl = ref('');
const isHelpDialogActive = ref(false);

// 网页版入口卡片：代码保留，当前按需求在下载页隐藏（改为 true 即可恢复显示）
const isWebVersionEnabled = false;

const releasesPage = 'https://github.com/HelloXiYangyang/SugarPaper/releases';
const releasesLatest = 'https://github.com/HelloXiYangyang/SugarPaper/releases/latest';

// 三个平台图标取自微信官网（weixin.qq.com）同款图标（白色实心版），
// 填充色改为 currentColor 以适配官网明暗主题；尺寸由 .platform-svg 统一控制（56px）。
const androidSvg = `
<svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' width='40' height='40' viewBox='0 0 40 40'>
  <defs>
    <path id='wx-android-mask-a' d='M0 0h33.684v18.947H0z'/>
  </defs>
  <g fill='none' fill-rule='evenodd'>
    <path d='M0 0h40v40H0z'/>
    <g opacity='1' transform='translate(3.158 11.158)'>
      <mask id='wx-android-mask-b' fill='#fff'>
        <use xlink:href='#wx-android-mask-a'/>
      </mask>
      <path fill='currentColor' d='M24.594 14.156a1.402 1.402 0 1 1-.003-2.803 1.402 1.402 0 0 1 .003 2.803m-15.504 0a1.402 1.402 0 1 1-.002-2.803 1.402 1.402 0 0 1 .002 2.803M25.097 5.72L27.9.874a.584.584 0 0 0-1.01-.583L24.05 5.2c-2.17-.989-4.608-1.54-7.21-1.54-2.6 0-5.038.552-7.209 1.54L6.794.291a.584.584 0 0 0-1.01.582l2.803 4.848C3.774 8.335.482 13.2 0 18.947h33.684C33.202 13.2 29.91 8.335 25.097 5.721' mask='url(#wx-android-mask-b)'/>
    </g>
  </g>
</svg>`;
const webSvg =
  '<svg viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><rect x="2.5" y="4" width="19" height="16" rx="2.2"/><path d="M2.5 8.5h19"/><path d="M6 6.5h.01M8.5 6.5h.01"/></svg>';
const windowsSvg = `
<svg xmlns='http://www.w3.org/2000/svg' width='40' height='40' viewBox='0 0 40 40'>
  <g fill='currentColor' fill-rule='evenodd'>
    <path d='M6.316 21.826v9.025l10.99 1.539V21.826zm12.045 0v10.712l14.463 2.026V21.826zM6.316 11.767v9.004h10.99V10.205zM32.824 8l-14.463 2.055v10.716h14.463z' opacity='1'/>
    <path fill='none' d='M0 0h40v40H0z'/>
  </g>
</svg>`;
const harmonySvg = `
<svg xmlns='http://www.w3.org/2000/svg' width='40' height='40' viewBox='0 0 40 40'>
  <g fill='currentColor' fill-rule='evenodd'>
    <path fill-rule='nonzero' d='M0 0h40v40H0z' opacity='0'/>
    <path d='M15.2 23.2c-.4-.2-.8-.3-1.3-.3s-.9.1-1.3.3c-.4.2-.7.5-.9.9-.2.4-.3.8-.3 1.3s.1.9.3 1.3c.2.4.5.7.9.9.4.2.8.3 1.3.3s.9-.1 1.3-.3c.4-.2.7-.5.9-.9.2-.4.3-.8.3-1.3s-.1-.9-.3-1.3c-.2-.4-.5-.7-.9-.9zM11.6 5C8 5 5 7.9 5 11.6v16.8C5 32 7.9 35 11.6 35h16.8c3.6 0 6.6-2.9 6.6-6.6V11.6C35 8 32.1 5 28.4 5H11.6zm-.9 5.3h1.5v3.2h3.5v-3.2h1.5v8h-1.5v-3.4h-3.5v3.4h-1.5v-8zm6.1 22h-5.7V31h5.7v1.3zm.7-4.8c-.4.6-.9 1.1-1.5 1.5-.6.4-1.3.5-2.1.5s-1.5-.2-2.1-.5c-.6-.4-1.1-.9-1.5-1.5-.4-.6-.5-1.3-.5-2.1s.2-1.5.5-2.1c.4-.6.9-1.1 1.5-1.5.6-.4 1.3-.5 2.1-.5s1.5.2 2.1.5c.6.4 1.1.9 1.5 1.5.4.6.5 1.3.5 2.1s-.2 1.5-.5 2.1zm10.6 1.1c-.2.4-.6.6-1 .8-.4.2-.9.3-1.4.3-.5 0-1.3-.1-1.9-.4-.5-.3-.9-.6-1.1-1.1V28h.1l.7-.4.2-.1.2.3.6.6c.3.2.7.3 1 .3.3 0 .7 0 1-.3.2-.2.3-.4.3-.7 0-.3 0-.4-.2-.5-.2-.2-.4-.3-.8-.4l-1.1-.3c-1.3-.4-2-1.1-2-2.3 0-1.2.1-.9.4-1.3.2-.4.6-.6 1-.8.4-.2.9-.3 1.4-.3.5 0 1.2.1 1.7.4.4.2.8.6 1 1v.3c.1 0 0 .1 0 .1l-.9.6-.2-.3c-.1-.2-.3-.4-.5-.5-.3-.2-.6-.2-.9-.2-.3 0-.7 0-.9.3-.2.2-.3.4-.3.7 0 .3 0 .4.2.5.2.2.4.3.8.4l1.1.3c1.3.4 1.9 1.1 1.9 2.3 0 1.2-.1.9-.3 1.3l-.1-.4zm-.2-10.4V13l-2 3.2h-.7l-2-3.2v5.1h-1.4v-8h1.4l2.5 4 2.5-4h1.3v8h-1.4l-.2.1z'/>
  </g>
</svg>`;

useHead({
  title: '下载 SugarPaper | 糖纸 · SugarPaper',
  meta: [
    {
      name: 'description',
      content:
        '下载糖纸 · SugarPaper：Android APK、Windows 桌面版，安装包托管在 GitHub Releases，按钮自动指向最新版本。'
    }
  ]
});

async function init() {
  try {
    const res = await fetch(import.meta.env.BASE_URL + 'updates/latest.json', { cache: 'no-store' });
    if (!res.ok) throw new Error('bad status');
    const data = await res.json();
    version.value = data.latest?.version || '';
    androidUrl.value = data.platforms?.android?.url || '';
    windowsUrl.value = data.platforms?.windows?.url || '';
    webUrl.value = data.platforms?.web?.url || '';
  } catch (e) {
    isError.value = true;
    console.error(e);
  }
  isLoading.value = false;
}

onMounted(() => init());

const downloadRouteRoot = computed(() => {
  const u = androidUrl.value || windowsUrl.value;
  return u ? u.slice(0, u.lastIndexOf('/') + 1) : '';
});

const androidApkName = computed(() => androidUrl.value.split('/').pop() || '');
const windowsExeName = computed(() => windowsUrl.value.split('/').pop() || '');

const windowsOptions = computed(() =>
  windowsUrl.value
    ? (() => {
        const exe = windowsExeName.value;
        return {
          [exe]: { title: '安装包 setup.exe' },
          [exe.replace(/\.exe$/, '.zip')]: { title: '绿色版 zip' }
        };
      })()
    : {}
);

const androidOptions = computed(() =>
  androidUrl.value
    ? (() => {
        const base = androidApkName.value.replace('-android.apk', '');
        return {
          [base + '-android.apk']: { title: '通用 APK（含全部 ABI）' },
          [base + '-android-arm64-v8a.apk']: { title: 'arm64-v8a（新机型，体积更小）' },
          [base + '-android-armeabi-v7a.apk']: { title: 'armeabi-v7a（较老机型）' },
          [base + '-android-x86_64.apk']: { title: 'x86_64（模拟器 / 部分平板）' }
        };
      })()
    : {}
);
</script>

<template>
  <div class="d-flex download-container flex-column page-margin-x-wide">
    <div v-if="!isError" class="d-flex flex-column mt-8">
      <h2 class="align-self-center text-center mb-4 text-h3 font-weight-bold fluent-title">下载 SugarPaper</h2>
      <p class="text-center align-self-center mb-12 fluent-subtitle">首先，选择适合您的平台和打包方式</p>

      <div class="mb-4 align-self-center d-flex flex-column">
        <v-skeleton-loader v-if="isLoading" width="200px" height="19.5px" />
        <p v-else class="text-center fluent-description" style="opacity: 75%; font-size: 13px">
          最新版本 v{{ version }} · 稳定版通道 · SHA-256 自动校验 · 官网按钮自动指向最新版本
        </p>
      </div>

      <div
        class="align-self-stretch d-flex ga-4 justify-center platforms-container flex-column flex-md-row flex-row align-content-start"
      >
        <DownloadPlatformCard
          platform-name="Android"
          :platform-icon-svg="androidSvg"
          description="Android 7.0+ · 通用安装包"
          :version="version"
          class="flex-grow-1 platform"
        >
          <div class="d-flex flex-row flex-wrap align-center justify-center mt-2 ga-1">
            <v-skeleton-loader v-if="isLoading" width="138.65px" height="48px" />
            <SplitDownloadButton
              v-else
              variant="primary"
              title="下载 APK"
              :download-infos="androidOptions"
              :selected-download-info="androidApkName"
              :download-route-root="downloadRouteRoot"
            />
          </div>
        </DownloadPlatformCard>

        <DownloadPlatformCard
          platform-name="Windows"
          :platform-icon-svg="windowsSvg"
          description="Windows 10 及更高版本"
          :version="version"
          class="flex-grow-1 platform"
        >
          <div class="d-flex flex-row flex-wrap align-center justify-center mt-2 ga-1">
            <v-skeleton-loader v-if="isLoading" width="138.65px" height="48px" />
            <SplitDownloadButton
              v-else
              variant="primary"
              title="下载 Windows"
              :download-infos="windowsOptions"
              :selected-download-info="windowsExeName"
              :download-route-root="downloadRouteRoot"
            />
          </div>
        </DownloadPlatformCard>

        <DownloadPlatformCard
          v-if="isWebVersionEnabled"
          platform-name="Web PWA"
          :platform-icon-svg="webSvg"
          description="在线可用 · 零安装 · 可离线"
          :version="version"
          class="flex-grow-1 platform"
        >
          <div class="d-flex flex-row flex-wrap align-center justify-center mt-2 ga-1">
            <FluentButton variant="primary" :href="webUrl || '/SugarPaper/app/'" target="_blank">
              <template #prepend><FluentSystemIcon name="documentSparkle" /></template>
              在线使用网页版
            </FluentButton>
          </div>
        </DownloadPlatformCard>

        <DownloadPlatformCard
          platform-name="HarmonyOS"
          :platform-icon-svg="harmonySvg"
          description="规划中 · 主流道为 AppGallery"
          class="flex-grow-1 platform"
        >
          <div class="d-flex flex-row flex-wrap align-center justify-center mt-2 ga-1">
            <FluentButton variant="hyperlink" :href="releasesLatest" target="_blank">
              <template #prepend><FluentSystemIcon name="bookOpen" /></template>
              查看发布
            </FluentButton>
          </div>
        </DownloadPlatformCard>
      </div>

      <div class="align-self-center d-flex flex-row ga-4 mt-8 flex-wrap justify-center">
        <FluentButton variant="hyperlink" :href="releasesPage" target="_blank">
          <template #prepend><FluentSystemIcon name="archive" /></template>
          查看全部版本
        </FluentButton>
        <FluentButton variant="hyperlink" href="/SugarPaper/download/mirrors" target="_blank">
          <template #prepend><FluentSystemIcon name="arrowClockwise" /></template>
          下载镜像
        </FluentButton>
        <FluentButton variant="hyperlink" @click="isHelpDialogActive = true">
          <template #prepend><FluentSystemIcon name="questionCircle" /></template>
          安装帮助
        </FluentButton>
      </div>

      <p class="text-center align-self-center fluent-description mt-6" style="opacity: 75%; font-size: 12.5px; max-width: 640px">
        安装包托管在 GitHub Releases，按钮自动指向最新版本并校验 SHA-256。若 GitHub 下载较慢，可在设置页配置镜像源。
      </p>
    </div>

    <div v-else class="d-flex flex-column mt-12 align-center">
      <h2 class="text-h4 mb-4 fluent-title">暂时无法读取版本信息</h2>
      <p class="fluent-description mb-6">请稍后重试，或直接前往 GitHub Releases 查看最新版本。</p>
      <FluentButton variant="primary" :href="releasesLatest" target="_blank">
        <template #prepend><FluentSystemIcon name="arrowDownload" /></template>
        前往 GitHub Releases
      </FluentButton>
    </div>

    <FluentDialog v-model="isHelpDialogActive" title="安装帮助">
      <ul style="padding-left: 1.2em; line-height: 1.8">
        <li><strong>Android：</strong>下载 APK 后用文件管理器打开安装；若提示「未知来源」，请在系统设置中允许安装该应用。</li>
        <li><strong>Windows：</strong>下载 setup.exe 双击安装（未签名会有 SmartScreen 提示，选择「仍要运行」即可）；绿色版 zip 解压后运行 SugarPaper.exe。</li>
        <li><strong>Web PWA：</strong>直接在浏览器使用，或通过浏览器「安装应用」功能安装到桌面离线使用。</li>
        <li><strong>数据：</strong>默认保存在本机，账号同步为可选项。</li>
      </ul>
      <template #actions>
        <FluentButton variant="primary" @click="isHelpDialogActive = false">知道了</FluentButton>
      </template>
    </FluentDialog>
  </div>
</template>

<style scoped lang="scss">
.platforms-container {
  align-items: stretch;
}

@media (min-width: 960px) {
  .platforms-container > .platform {
    flex: 1 1 0;
    min-width: 0;
  }
}

.fluent-title {
  font-family: var(--font-family-base);
  color: var(--fill-color-text-primary);
}

.fluent-subtitle {
  font-family: var(--font-family-base);
  color: var(--fill-color-text-secondary);
  font-size: 16px;
}

.fluent-description {
  font-family: var(--font-family-base);
  color: var(--fill-color-text-secondary);
}
</style>
