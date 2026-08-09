# 糖纸 Design System（设计系统）

唯一的视觉基准，所有端（Vue / Kotlin / C# / ArkTS / 小程序）只消费本目录，不跨端复制 UI 代码。

## 目录

```text
design-system/
├── tokens/           # 设计令牌（JSON，唯一权威定义）
│   ├── colors.json   # 颜色（浅色 / 深色 / 品牌 / 科目色板）
│   ├── typography.json
│   ├── radius.json
│   ├── spacing.json
│   ├── shadows.json
│   └── motion.json
├── components/       # 组件规范（结构 / 状态 / 尺寸 / 交互，附基准图）
├── icons/            # 图标库（SVG 源文件，无 emoji）
└── baseline/         # 视觉基准图（各组件各状态，视觉对拍用）
```

## 消费方式

| 端 | 转换 |
|---|---|
| 网页版（Vue3） | tokens → CSS 自定义属性（`src/styles/tokens.css`） |
| 安卓（Kotlin + Compose） | tokens → `Color.kt` / `Dimens.kt` / `Theme.kt` |
| Windows（C# + Avalonia） | tokens → `ResourceDictionary` |
| 鸿蒙（ArkTS） | tokens → 资源变量 |
| 小程序（WXSS） | tokens → CSS 变量 |

## 规则

- 手机形态（手机网页 / 安卓 / 鸿蒙手机）界面必须一致；桌面形态（电脑网页 / Windows / 鸿蒙电脑 / Linux / macOS）界面必须一致。
- 只允许消费 tokens，禁止硬编码颜色 / 字号 / 间距。
- 主题只保留两套：浅色（默认，白色为主）+ 深色。
