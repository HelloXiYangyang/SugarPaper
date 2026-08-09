# 🧁 糖纸 · SugarPaper —— 零服务器多平台发布·自动更新·官网方案 v2.0

> 目标：不租服务器、不自己建站、不买任何云服务，仅用 GitHub 的免费能力，同时实现三件事：
> 1. **自动更新**：Android / Windows / 鸿蒙 / Web PWA / 微信小程序 的版本检测与更新分发；
> 2. **网页版上线**：把现有 `web/` PWA 部署到 GitHub Pages；
> 3. **官网**：搭建官方网站（介绍 + 截图 + 各平台最新版下载按钮）。
>
> 前提条件：仓库必须保持 **公开**。公共仓库的 GitHub Actions 免费无限分钟、Releases 免费无限带宽；私有仓库每月只有约 2000 分钟构建额度。

---

## 1. 一句话结论

**GitHub Releases 存安装包 + GitHub Pages 存 update.json 并托管官网与网页版 + GitHub Actions 自动打包与部署 = 零服务器的自动更新、官网、网页版，三合一。**

三个组件全部是 GitHub 免费能力，不是"服务器"：

| 组件 | 作用 | 费用 |
| --- | --- | --- |
| GitHub Releases | 存放各平台安装包（APK / exe / HAP / zip），单文件上限 2 GB | 免费，不限带宽 |
| GitHub Pages | 静态托管 `update.json`，避免 API 限流 | 免费 |
| GitHub Actions | 打 tag 后自动构建各平台、上传 Release、生成元数据 | 公共仓库免费无限分钟 |

---

## 2. 总体数据流

### 2.1 发布侧（每次发版）

```text
git push tag v0.26.0
        │
        ▼
GitHub Actions 并行构建：
  Android APK / Windows exe / Web 产物
        │
        ▼
上传到 GitHub Releases（v0.26.0）
        │
        ▼
计算每个文件的 SHA-256
        │
        ▼
更新 Pages 上的 updates/latest.json（提交到 gh-pages 分支）
```

### 2.2 客户端侧（每次启动 / 手动检查）

```text
启动后延迟 5~10 秒（或设置页手动点"检查更新"）
        │
        ▼
GET https://helloxiyangyang.github.io/SugarPaper/updates/latest.json
        │
        ▼
比较远端 build 号 > 本地 build 号？
   ├─ 否 → 结束（"已是最新版本"）
   └─ 是 → 弹更新对话框（版本号 + 更新说明）
              │
              ▼
用户点"下载更新" → 流式下载 + 进度条
              │
              ▼
校验 SHA-256 → 交给各平台安装器 → 重启应用
```

---

## 3. 核心元数据：update.json

所有客户端只认这一份文件，放在 GitHub Pages（或 `raw.githubusercontent.com`），不调用 GitHub API（API 匿名限流 60 次/小时/IP，不够用）。

```json
{
  "app": "SugarPaper",
  "latest": {
    "version": "0.26.0",
    "build": 44,
    "published_at": "2026-08-07T00:00:00Z",
    "notes": "- 修复日历跳转问题\n- 新增专注统计"
  },
  "platforms": {
    "android": {
      "url": "https://github.com/HelloXiYangyang/SugarPaper/releases/download/v0.26.0/SugarPaper-0.26.0-universal.apk",
      "sha256": "a1b2c3..."
    },
    "windows": {
      "url": "https://github.com/HelloXiYangyang/SugarPaper/releases/download/v0.26.0/SugarPaper-0.26.0-windows-x64-setup.exe",
      "sha256": "d4e5f6..."
    },
    "harmonyos": {
      "url": "https://github.com/HelloXiYangyang/SugarPaper/releases/download/v0.26.0/SugarPaper-0.26.0.hap",
      "sha256": "m3n4o5..."
    }
  }
}
```

关键点：

- **build 用整数**（Android 的 versionCode），比字符串版本号可靠，各平台都能比较。
- 每个平台只读自己那一项，互不影响。
- `sha256` 是必须项，下载完先校验再执行安装。
- 进阶（可选）：用 Ed25519 私钥对整个 JSON 签名，客户端内置公钥验签。私钥放 GitHub Actions Secrets，不进仓库。

---

## 4. 各平台方案明细

| 平台 | 分发物 | 更新方式 | 是否需要付费证书 |
| --- | --- | --- | --- |
| Android | 通用 APK | 应用内下载 APK → 系统安装器 | 否（APK 不强制签名，建议自签名） |
| Windows | Inno Setup 制作的 setup.exe | 下载 exe → 静默安装 → 重启 | 否（不签名会有 SmartScreen 警告） |
| 鸿蒙 | AppGallery 为主，HAP 为辅 | AppGallery 自动更新 / HAP 手动安装 | 是（华为开发者账号） |
| Web PWA | GitHub Pages 静态站点 | Service Worker 版本更新 + 提示刷新 | 否 |
| 微信小程序 | 微信平台托管 | 微信平台发布审核，新版本经审核后自动生效；可用 `wx.getUpdateManager` 提示用户重启小程序 | 是（需注册微信小程序账号并完成主体认证） |

---

### 4.1 Android

- **分发物**：`flutter build apk --release` 生成的通用 APK。不要用 AAB（AAB 只能上 Google Play，不能直接安装）。
- **版本比较**：用 versionCode（pubspec 里 `0.26.0+44` 的 `44`）。
- **下载**：用 http 流式下载到 `getApplicationDocumentsDirectory()` 下的临时文件，不需要存储权限。
- **安装**：manifest 加 `<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES"/>`，用 FileProvider + `ACTION_VIEW` 调起系统安装器（Flutter 里可直接用 `open_filex` 包）。用户首次需要允许"安装未知来源应用"，这是 Android 系统限制，无法绕过。
- **注意**：若以后上 Google Play，Play 版改用官方 `in_app_update` 包（Play 自己更新），GitHub APK 渠道保留给官网直接下载用户。

### 4.2 Windows

- **分发物**：推荐 Inno Setup 打包的 `setup.exe`（免费工具，支持静默参数 `/VERYSILENT /NORESTART`），同时附一个绿色版 zip 备选。
- **更新流程**：下载 setup.exe → 校验 SHA-256 → `Process.start(installerPath, ['/VERYSILENT', '/NORESTART'])` → 应用退出 → 安装完成后用户重新打开。
- **绿色版备选**：下载 zip → 解压到临时目录 → 写一个 `update.bat`：等主程序退出后把新文件覆盖到安装目录并重新启动。免安装、免 UAC。
- **注意**：未签名 exe 首次运行会有 SmartScreen 蓝屏警告，属正常现象；要消除需要买代码签名证书（每年约 ¥1000+，可选）。

### 4.3 鸿蒙（HarmonyOS）

- **现状**：官方没有现成 Flutter 支持，需要 OpenHarmony 社区的 `flutter_flutter` fork 或 ArkTS 重写（这是另一个大话题，本方案不展开）。
- **主渠道：AppGallery（华为应用市场）**。上架后系统自动更新，零服务器。这是鸿蒙上体验最好的路。
- **GitHub 辅助渠道**：把 HAP 传 GitHub Releases，应用内"检测到新版 → 下载 HAP → 调起系统文件安装器"。鸿蒙系统限制**第三方应用不能静默安装**，用户必须在设置里开启"允许安装外部来源应用"并手动确认，只能做到"自动下载 + 引导安装"。
- 结论：鸿蒙的自动更新交给 AppGallery；GitHub 只做下载分发。

### 4.4 Web PWA

- 网页版（`web/js/updater.js`）采用「版本元数据 + SW 外壳」双通道检测：
  - **版本元数据**：启动 3 秒后读取 `updates/latest.json`（`../../updates/latest.json`，兼容 `/app/` 子路径），与本地 `APP_VERSION` 语义化对比；发现新版弹出横幅（立即刷新 / 更新记录 / 本次忽略），设置页「更新」卡片可手动检查并一键刷新；
  - **SW 外壳**：`web/sw.js`（缓存名 `sugarpaper-shell-v0.27.0`）每次发版 bump `CACHE_NAME`；`updatefound` + `skipWaiting()` + `clients.claim()` 检测到新外壳时复用同一横幅提示刷新，`controllerchange` 后自动刷新接管；
  - 元数据请求带时间戳参数且不落缓存（SW 对 `/updates/latest.json` 直连网络，保证每次都拿到最新版本号）。
- **部署**：GitHub Pages 就是免费静态托管，`push` 到 main 后由 Actions 自动部署，PWA 顺带解决。

---

## 5. Flutter 客户端实现设计

新增一个共用模块，所有桌面/移动端复用同一套逻辑：

```text
app/lib/
  data/
    update_service.dart      # 检查更新、下载、校验、安装分发
  models/
    update_info.dart         # update.json 解析模型
  ui/settings/
    update_page.dart         # 检查更新入口
    update_dialog.dart       # 更新对话框（说明 + 进度 + 按钮）
```

需要的依赖：

```yaml
dependencies:
  package_info_plus: ^8.x      # 读当前版本号 / build 号
  dio: ^5.x                    # 流式下载 + 进度回调
  open_filex: ^4.x             # Android 打开 APK 调起安装器
  crypto: 已有                 # SHA-256 校验
```

核心流程（伪代码）：

```dart
Future<void> checkForUpdate() async {
  final local = await PackageInfo.fromPlatform();
  final json = await httpGet('https://helloxiyangyang.github.io/SugarPaper/updates/latest.json');
  final info = UpdateInfo.fromJson(json);
  if (info.latest.build <= int.parse(local.buildNumber)) return; // 已最新

  final platformEntry = info.platforms[Platform.currentKey];   // android/windows/...
  final file = await downloadWithProgress(platformEntry.url);   // dio 流式 + 进度
  final hash = sha256Of(file);
  if (hash != platformEntry.sha256) throw '校验失败';

  await PlatformInstaller.install(file);  // 见下表
}
```

各平台安装动作：

| 平台 | 安装动作 |
| --- | --- |
| Android | `open_filex` 打开 APK → 系统安装器 |
| Windows | `Process.start(exe, ['/VERYSILENT', '/NORESTART'])` → 退出应用 |
| 鸿蒙 | 打开 HAP 文件 → 系统安装器（用户确认） |

检查策略建议：

- 启动后延迟 5~10 秒检查一次，避免影响冷启动；
- 设置页提供"检查更新"手动入口；
- 把检查结果缓存（如 24 小时内不重复弹窗），防止频繁打扰。

---

## 6. GitHub Actions 自动发布流水线

新建 `.github/workflows/release.yml`，触发方式：推送 `v*` 标签或手动触发。

```yaml
name: Release
on:
  push:
    tags: ['v*']
  workflow_dispatch:

jobs:
  android:    # ubuntu-latest，flutter build apk --release
  windows:    # windows-latest，flutter build windows + Inno Setup
  web:        # ubuntu-latest，flutter build web（或拷贝 web/ 目录）

  publish:    # 汇总各产物 → 计算 sha256 → 创建 Release 上传 → 更新 gh-pages 的 latest.json
```

需要的 Secrets（仓库 Settings → Secrets and variables）：

| Secret | 用途 | 必填 |
| --- | --- | --- |
| `ANDROID_KEYSTORE` / `ANDROID_KEYSTORE_PASSWORD` 等 | Android 签名 | 建议 |
| `SIGNING_PRIVATE_KEY`（Ed25519） | update.json 签名 | 可选 |

---

## 9. 网页版上线与官网部署（零服务器）

### 9.1 关键问题：一个仓库能部署多个网站吗？

**能，但有一个限制：**

- 一个 GitHub 仓库只能发布**一个** GitHub Pages 站点；
- 但一个站点内部可以用**子路径**放任意多个"网站"；
- 想要两个完全独立的网址（各自绑不同域名），则需要**两个仓库**（都是免费的，不算服务器）。

### 9.2 方案 A：单仓库子路径（推荐，现阶段直接用）

一个 Pages 站点同时放官网和网页版：

| 入口 | URL |
| --- | --- |
| 官网（根路径） | https://helloxiyangyang.github.io/SugarPaper/ |
| 网页版（子路径） | https://helloxiyangyang.github.io/SugarPaper/app/ |

优点：

- 一个仓库、一套 Actions、一个部署，全免费；
- 网页版现有代码已经全部使用相对路径（`register('sw.js')`、`start_url: "index.html"`、`./` 资源引用），**天然兼容子路径，几乎不用改**；
- 以后买了自定义域名（如 sugarpaper.cn），子路径结构原样保留：`sugarpaper.cn/` 是官网、`sugarpaper.cn/app/` 是网页版。

### 9.3 方案 B：多仓库独立站点（以后要独立域名时再拆）

| 仓库 | 站点 URL |
| --- | --- |
| HelloXiYangyang/SugarPaper（本仓库） | https://helloxiyangyang.github.io/SugarPaper/ |
| HelloXiYangyang/SugarPaper-Website（新建） | https://helloxiyangyang.github.io/SugarPaper-Website/ |

- 每个仓库一个 Pages 站点，可各自绑一个自定义域名（如 www.sugarpaper.cn 与 app.sugarpaper.cn）；
- 缺点：维护两个仓库、两套流水线；
- 建议：现阶段用方案 A，等真有独立域名需求再拆，迁移成本很低（都是静态文件，拷贝目录即可）。

### 9.4 官网设计

官网源码放在本仓库的 `site/` 目录：

```text
site/                    # 官网源码
  index.html             # 首页
  css/theme.css          # 可复用糖纸主题色
  js/downloads.js        # 下载区：读 updates/latest.json 自动渲染最新版按钮
  assets/                # 截图、图标
```

页面结构（标准官网布局）：

1. Hero 区：应用名 + slogan + 主下载按钮（自动指向最新版）；
2. 功能亮点：作业管理、专注计时、统计、离线优先……
3. 截图 / 演示区；
4. 平台支持：Android / Windows / 鸿蒙 / Web / 微信小程序；
5. 下载区：按平台出按钮（Android APK、Windows exe、HAP）；
6. 更新日志：展示最近版本说明（可读 GitHub Releases 或 latest.json）；
7. 常见问题 FAQ；
8. 页脚：GitHub 仓库链接 + 开源许可（GPL-3.0）。

### 9.5 下载按钮如何"始终指向最新版"

官网下载区**不写死版本号**，用 JS 读同一份 `updates/latest.json`（就是自动更新方案里的那份元数据）：

```js
// site/js/downloads.js（简化示意）
fetch('/SugarPaper/updates/latest.json')
  .then(r => r.json())
  .then(data => {
    const p = data.platforms;
    document.querySelector('#dl-android').href = p.android.url;
    document.querySelector('#dl-windows').href = p.windows.url;
    document.querySelector('#dl-hap').href = p.harmonyos.url;
    document.querySelector('#ver').textContent = data.latest.version;
  });
```

好处：

- 一份元数据两处用（客户端自动更新 + 官网下载按钮），发新版时只更新 latest.json，官网按钮自动指向新版本；
- 同站读取，无跨域、无 API 限流；
- 兜底：主按钮再放一个 `https://github.com/HelloXiYangyang/SugarPaper/releases/latest` 链接（GitHub 自动跳转到最新 Release 页），元数据万一没更新也能用。

### 9.6 部署流水线（GitHub Actions，全自动）

新建 `.github/workflows/deploy-pages.yml`：

```yaml
name: Deploy Pages
on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      pages: write
      id-token: write
    steps:
      - uses: actions/checkout@v4
      - name: 组装站点
        run: |
          mkdir -p _site
          cp -r site/* _site/          # 官网 → 根路径
          cp -r web _site/app          # 网页版 → /app/
          cp -r updates _site/updates  # 元数据 → /updates/
      - uses: actions/configure-pages@v5
      - uses: actions/upload-pages-artifact@v3
        with:
          path: _site
      - uses: actions/deploy-pages@v4
```

配套设置（只需要你点一次）：

1. 仓库 **Settings → Pages → Source** 选择 **GitHub Actions**；
2. 之后每次 push main，官网 + 网页版 + latest.json 自动一起更新上线；
3. 网页版发版时 bump `web/sw.js` 里的 `CACHE_NAME`，用户刷新即拿到新版本。

### 9.7 PWA 在子路径下的适配清单（已检查，基本不用改）

已确认网页版现状：

- `navigator.serviceWorker.register('sw.js')` 是相对路径 → 部署在 `/SugarPaper/app/` 后自动解析为 `/SugarPaper/app/sw.js`，作用域正确；
- manifest 的 `start_url: "index.html"` 是相对路径 → 自动解析到 `/SugarPaper/app/index.html`；
- 全部资源引用都是 `./` 相对路径 → 兼容子路径。

部署后做一次真机验证：访问 `/app/` → 安装 PWA → 断网刷新，确认离线可用。

### 9.8 域名展望（不买也能用，买了更好）

- 不买域名：`helloxiyangyang.github.io/SugarPaper/` 完全可用；
- 买域名后：方案 A 直接绑到根（如 sugarpaper.cn），官网 = `sugarpaper.cn/`，网页版 = `sugarpaper.cn/app/`；
- 想要两个独立子域名（www 与 app）：再走方案 B 拆两个仓库。

---

## 10. 分阶段落地路线

### 阶段 1（零证书、本周就能做）：Android + Windows + Web PWA + 官网

1. 建 `updates/latest.json`（先放仓库，客户端从 raw 或 Pages 读）；
2. Flutter 加 `update_service.dart` + 设置页入口 + 更新对话框；
3. Android APK、Windows setup.exe 两条安装链路跑通；
4. Web 端 SW 版本 bump + 刷新提示 + GitHub Pages 自动部署；
5. 建官网 `site/`（首页 + 功能 + 下载区），下载区读 latest.json 自动指向最新版；
6. 建 `deploy-pages.yml`：官网放根路径、网页版放 `/app/`，一次部署全上线；
7. 验收：手动在 GitHub 发一个 v0.26.0 假 Release，各端能弹出更新、下载、安装；打开官网能看到最新版下载按钮。

### 阶段 2：鸿蒙

1. 鸿蒙上 AppGallery（若用 OpenHarmony Flutter fork 另行评估）；
2. 可选：Ed25519 签名 update.json，加固防篡改。

---

## 11. 风险与注意事项

- **中国大陆下载 GitHub 慢**：Release 直连可能不稳定，可在设置页提供镜像源配置（如 ghproxy 类免费代理），或后续用 jsDelivr 等免费 CDN 缓存元数据。
- **未签名程序的安全警告**：Windows SmartScreen 会拦截，属平台安全机制，无法用 GitHub 绕过。
- **鸿蒙无法 GitHub 静默安装**：平台政策限制，只能走商店或手动确认安装。
- **公共仓库才全免费**：一旦仓库设为私有，Actions 分钟数受限；如果想长期免费，保持公开。
- **Release 文件命名要稳定**：建议统一 `SugarPaper-{版本}-{平台}-{架构}.{ext}`，便于自动化脚本匹配。
- **一个仓库一个 Pages 站点**：官网 + 网页版用子路径共享一个站点；以后要独立域名/子域名需拆成多个仓库。
- **仓库改名会换 URL**：Pages 路径包含仓库名，改名后旧链接失效（可用自定义域名规避）。
- **GitHub 国内访问时快时慢**：官网和网页版可后续挂 jsDelivr / Cloudflare 这类免费 CDN 加速（仍是静态托管，不算服务器）。

---

## 12. 下一步

方案确认后，建议按阶段 1 开始实施：

1. 先写 Flutter 更新模块 `update_service.dart` + 更新 UI + 平台安装器（Android/Windows）；
2. 建官网 `site/`（含下载区自动读取 latest.json）；
3. 建 `.github/workflows/release.yml` 发布流水线 + `.github/workflows/deploy-pages.yml` 部署流水线；
4. 做 Web PWA 的版本提示与子路径适配验证；
5. 你在仓库 Settings → Pages 里点一下"Source = GitHub Actions"，之后全部自动。
