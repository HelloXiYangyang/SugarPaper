---
icon: rocket
title: 版本发布流程
category: 管理
---

# 版本发布流程

仓库遵循「即做即更」规则：小功能 / 修复即升小版本发布，重要功能升大版本，禁止攒批。

1. 推送 `v*` 标签到 GitHub；
2. GitHub Actions 自动构建 Android APK 与 Windows 桌面版安装包；
3. 上传到 [Releases](https://github.com/HelloXiYangyang/SugarPaper/releases)，计算 SHA-256 并回写 `updates/latest.json`；
4. 官网下载按钮与各端自动更新随之指向新版本。

::: warning

如果发布工作流运行失败，需要手动同步一次 `updates/latest.json`，
否则官网下载按钮会停留在旧版本（曾因此出现安卓版下载不到最新包的问题）。

:::
