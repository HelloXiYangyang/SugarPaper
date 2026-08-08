# 糖纸 · SugarPaper 官网

糖纸官方网站在线地址：<https://helloxiyangyang.github.io/SugarPaper/>

本目录源码基于 [ClassIsland 官网](https://github.com/ClassIsland/classisland-web-vuetify)（MIT 许可）改造：
保留其 Vue 3 + Vuetify + vite-ssg 技术栈、Fluent 组件体系、图标库与动画交互，内容全部替换为糖纸的产品内容。

## 开发环境搭建

- **Node.js**：需要 Node 20 及以上版本；
- **Yarn**：必须使用 Yarn 进行依赖管理（`yarn.lock` 已提交）。

```sh
yarn install
yarn dev      # 开发服务器
yarn build    # 静态构建，产物在 dist/
```

## 部署说明

- 构建产物部署在 GitHub Pages 的 `/SugarPaper/` 子路径，`vite.config.mts` 中 `base` 已设置为 `/SugarPaper/`；
- 更新元数据从 `/SugarPaper/updates/latest.json` 读取，与客户端自动更新共用一份；
- **动画演示视频**：把录好的演示视频放到 `public/demos/reminder-demo.mp4`，构建后会自动部署到 `/SugarPaper/demos/reminder-demo.mp4` 并被首页引用。

## 许可证

源码以 GNU AGPL-3.0 开源协议发布（与主仓库一致）；原 ClassIsland 官网部分以 MIT 许可授权使用。
