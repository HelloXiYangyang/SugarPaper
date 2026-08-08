/**
 * 主入口文件
 *
 * 本文件负责初始化Vue应用，包括安装必要的插件和挂载根组件。
 */

// 导入插件注册逻辑
// Plugins
import { registerPlugins } from '@/plugins';

// 导入App组件
// Components
import App from './App.vue';

//导入虚拟模块以注册SVG图标
import 'virtual:svg-icons-register';

import './styles/tailwind.css';
import './styles/main.scss';
import {ViteSSG} from "vite-ssg";
import {routes} from "vue-router/auto-routes";
const asciiLogo =
  "---------------------------------------------------------------\n" +
  "   ____  __      __  ____    ____                            \n" +
  "  / ___|| |     \\ \\/ / |   |  _ \\ _ __ ___   __ _ _ __ ___   \n" +
  "  \\___ \\| |      \\  /| |   | |_) | '__/ _ \\ / _` | '_ ` _ \\  \n" +
  "   ___) | |___   /  \\| |___|  __/| | | (_) | (_| | | | | | | \n" +
  "  |____/|_____| /_/\\_\\_____|_|   |_|  \\___/ \\__,_|_| |_| |_| \n" +
  "---------------------------------------------------------------\n" +
  "糖纸 · SugarPaper —— 一款功能强、可定制、跨平台的作业管理小助手。\n";

// 创建Vue应用实例，指定根组件为App
export const createApp = ViteSSG(
  App,
  { routes, base: '/SugarPaper/' },
  ({ app, router, routes, isClient, initialState }) => {
    // 在这里使用例如 app.use(pinia) 或者 router.use()
    registerPlugins(app);
    if (isClient) {
      console.log("\x1b[36m" + asciiLogo + "\x1b[0m");
    }
  }
)
