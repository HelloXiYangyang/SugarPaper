---
icon: arrows-rotate
title: 零服务器自动更新
category: 管理
---

# 零服务器自动更新

糖纸的自动更新不需要任何自建服务器：

- **GitHub Releases** 存放安装包；
- **GitHub Pages** 存放 `updates/latest.json` 元数据；
- **GitHub Actions** 在发布时自动构建并上传。

## 客户端行为

- **安卓版 / Windows 版**：启动后或手动「检查更新」时读取 `latest.json`，比较 build 号，发现新版后流式下载并校验 SHA-256，再交给系统安装器；
- **网页版**：启动后自动对比版本号，发现新版提示「发现新版本 · 立即刷新」；Service Worker 会后台预缓存新版，点「立即升级」秒级生效。
