---
icon: hammer
title: 运行与构建
category: 开发文档
---

# 本地运行与构建

## 网页版（零依赖）

```sh
# 方式一：直接用浏览器打开
web/index.html

# 方式二：本地静态服务
node web/serve.js 8080
```

## Flutter 版（安卓 / Windows）

```sh
# 环境要求：Flutter 3.22+、JDK 17、Android SDK
cd app
flutter pub get
flutter test                 # 单元测试
flutter build apk --release  # 正式包
flutter build windows        # Windows 桌面版
```

APK 输出：`app/build/app/outputs/flutter-apk/app-release.apk`。
Windows 安装包可用 `app/build_installer_windows.ps1` 配合 Inno Setup 生成。

## 官网（homepage/）

```sh
cd homepage
yarn install
yarn dev      # 开发服务器
yarn build    # 静态构建，产物在 dist/
```

## 文档站（docs-src/）

```sh
cd docs-src
pnpm install
pnpm docs:dev    # 开发服务器
pnpm docs:build  # 静态构建，产物在 src/.vuepress/dist/
```

## 测试

```sh
node web/test/unit.test.js          # 解析器 + 统计引擎单元测试
node web/test/e2e.test.js           # 端到端交互测试（需本机 Edge/Chrome + Playwright）
node web/test/screenshot.js         # 生成多断点界面截图
node web/test/verify_docs.js        # 文档同步校验（16 科 + 头像三方一致）
```
