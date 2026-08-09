/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: CC-BY-NC-SA-4.0
 */

import { sidebar } from "vuepress-theme-hope";

export const zhSidebar = sidebar({
  "/": [
    "",
    {
      text: "首页",
      link: "index.md",
    },
  ],
  "/get-started/": [
    {
      icon: "fa-solid fa-book",
      text: "快速上手",
      children: [
        "README.md",
        "setup.md",
        "account.md",
        "input.md",
        "manage.md",
        "sync.md",
        "next.md",
      ],
    },
  ],
  "/app/": [
    {
      icon: "fa-solid fa-lightbulb",
      text: "应用帮助",
      children: [
        "README.md",
        "home.md",
        "calendar.md",
        "focus.md",
        "notes.md",
        "photo.md",
        "rewards.md",
        "friends.md",
        "themes.md",
        "roles.md",
      ],
    },
  ],
  "/management/": [
    {
      icon: "fa-solid fa-server",
      text: "管理",
      children: [
        "README.md",
        "update.md",
        "release.md",
        "backup.md",
        "mirror.md",
        "privacy.md",
        "faq.md",
      ],
    },
  ],
  "/dev/": [
    {
      icon: "fa-solid fa-code",
      text: "开发文档",
      children: [
        "README.md",
        "structure.md",
        "stack.md",
        "build.md",
        "arch.md",
        "contributing.md",
      ],
    },
  ],
  "/community/": [
    {
      icon: "fa-solid fa-users",
      text: "讨论社区",
      children: [
        "README.md",
        "feedback.md",
        "contribute.md",
        "legal.md",
        "changelog.md",
      ],
    },
  ],
});
