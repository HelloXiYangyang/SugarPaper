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

const releasesPage = 'https://github.com/HelloXiYangyang/SugarPaper/releases';
const releasesLatest = 'https://github.com/HelloXiYangyang/SugarPaper/releases/latest';

const androidSvg =
  '<svg viewBox="0 0 24 24" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M9.6 3.7 8.2 1.5M14.4 3.7l1.4-2.2"/><path d="M6.2 13.2V8.8a5.8 5.8 0 0 1 11.6 0v6.4a1.6 1.6 0 0 1-1.6 1.6H7.8a1.6 1.6 0 0 1-1.6-1.6z"/><path d="M9.2 10.4v1.8M14.8 10.4v1.8"/><path d="M6.2 15.2l-3.4 1.8M17.8 15.2l3.4 1.8"/></svg>';
const webSvg =
  '<svg viewBox="0 0 24 24" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><rect x="2.5" y="4" width="19" height="16" rx="2.2"/><path d="M2.5 8.5h19"/><path d="M6 6.5h.01M8.5 6.5h.01"/></svg>';
const harmonySvg =
  '<svg viewBox="0 0 24 24" stroke-width="3.2" stroke-linecap="round"><path d="M19 12a7 7 0 1 1-7-7"/></svg>';

useHead({
  title: '下载 SugarPaper | 糖纸 · SugarPaper',
  meta: [
    {
      name: 'description',
      content:
        '下载糖纸 · SugarPaper：Android APK、网页版 PWA、Windows 桌面版，安装包托管在 GitHub Releases，按钮自动指向最新版本。'
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
          platform-icon="windows"
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
          platform-name="鸿蒙 HAP"
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
