# 糖纸 · SugarPaper 文档站

文档站在线地址：<https://helloxiyangyang.github.io/SugarPaper/docs/>

本目录基于 [ClassIsland 文档](https://github.com/ClassIsland/classisland-docs-next)
（VuePress 2 + vuepress-theme-hope）改造，保留其主题、图标、搜索、明暗切换等功能与视觉风格，
内容全部替换为糖纸的文档。原文档以 CC BY-NC-SA 4.0 许可授权（见 `LICENSE`）。

## 开发

```sh
pnpm install
pnpm docs:dev      # 开发服务器
pnpm docs:build    # 静态构建，产物在 src/.vuepress/dist/
```

构建产物部署在 GitHub Pages 的 `/SugarPaper/docs/` 子路径（`src/.vuepress/config.ts` 中 `base` 已配置）。
