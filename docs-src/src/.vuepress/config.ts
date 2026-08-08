import { defineUserConfig, Plugin } from "vuepress";
import theme from "./theme.js";

export default defineUserConfig({
  base: "/SugarPaper/docs/",

  locales: {
    "/": {
      lang: "zh-CN",
      title: "糖纸 · SugarPaper 文档",
      description: "糖纸 · SugarPaper 的文档：快速上手、应用帮助、管理、开发文档与讨论社区。",
    },
  },
  head: [
    ["link", { rel: "icon", href: "/SugarPaper/docs/logo.svg", type: "image/svg+xml" }],
  ],
  theme
  // 和 PWA 一起启用
  // shouldPrefetch: false,
});
