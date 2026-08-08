---
icon: layer-group
title: 技术栈
category: 开发文档
---

# 技术栈

| 版本 | 技术路线 |
| :--- | :--- |
| 网页版 | 原生 HTML5 + CSS3 + JavaScript（零构建、零依赖） |
| 安卓 / Windows | Flutter（共享 `app/lib/` 核心代码） |
| 官网 | Vue 3 + Vuetify 3 + Vite + vite-ssg |
| 文档站 | VuePress 2 + vuepress-theme-hope |
| 加密同步 | PBKDF2 → Ed25519，AES-256-GCM 端到端加密 + 签名 |
| 传输 | Nostr 中继（密文转发）+ WebRTC DataChannel（P2P 直连） |
| 测试 | 网页版：node 单元测试 + Playwright e2e；Flutter：flutter_test |
