---
icon: folder-open
title: 项目结构
category: 开发文档
---

# 项目结构

仓库采用「单一 README · 多版本分区」管理：

| 目录 | 说明 |
| :--- | :--- |
| `web/` | 网页版（PWA）：原生 HTML5 + CSS3 + JavaScript，零构建、零依赖 |
| `app/` | Flutter 多平台工程：一套代码编译至 Android / Windows |
| `homepage/` | 官网（Vue 3 + Vuetify + vite-ssg，本仓库源码基于 ClassIsland 官网改造） |
| `docs-src/` | 文档站（VuePress 2 + Theme Hope，风格参考 ClassIsland 文档） |
| `updates/` | 更新元数据 `latest.json`（供客户端自动更新） |
| `.github/workflows/` | Pages 部署与版本发布流水线 |
