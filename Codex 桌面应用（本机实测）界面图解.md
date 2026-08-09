# Codex 桌面应用（本机实测）界面图解

> 本文档**不做提炼、不做虚构**：所有页面文字均直接读取自本机正在运行的 Codex 窗口的 UI Automation 控件文本（控件 Name 即界面显示文字），并附坐标换算后的布局。图标无法以文字表达的位置用 `[▣]` 占位；界面实际是英文（安装包默认英文，设置里 Language 显示"简体中文"但未生效到界面），英文文字原样保留。

---

## 0. 实测环境

| 项目 | 实测值 |
| :--- | :--- |
| 应用 | Codex 桌面应用（窗口标题：**ChatGPT**） |
| 安装包 | OpenAI.Codex_26.803.5235.0_x64（MSIX 包） |
| 安装路径 | `C:\Program Files\WindowsApps\OpenAI.Codex_26.803.5235.0_x64__2p2nqsd0c76g0` |
| 系统 | Windows，屏幕 1440×960 逻辑像素（200% DPI，物理 2880×1920） |
| 界面语言 | 英文（设置 → General → Language 显示"简体中文"，但实际控件文字为英文） |
| 采集方法 | 读取运行中窗口的 UI Automation 树（控件真实文字 + 坐标），逐页点击侧边栏/设置项抓取；全程未修改任何设置 |
| 主窗口 | 1453×925 逻辑像素，左侧栏 275px，中央对话区 1000px，右侧面板 666px |

---

## 1. 技术栈（来自安装包实测）

| 层 | 实测依据 |
| :--- | :--- |
| 桌面壳 | **Electron**：`app.asar`、`.vite/build/main-*.js` 主进程、窗口类 `Chrome_WidgetWin_1`、原生 File/Edit/View/Help 菜单 |
| 前端 UI | **React + Vite**：`webview/` 目录、`index.html` 入口、`webview/assets/*.js` 模块、`.vite/build/*.js` |
| 智能体内核 | **Rust 编写的 `codex.exe`**（293MB，对应开源仓库 openai/codex 的 codex-rs 引擎） |
| 命令执行 | `codex-command-runner.exe`（命令运行器）、`codex-windows-sandbox-setup.exe`（Windows 沙箱） |
| 代码模式 | `codex-code-mode-host.exe` / `codex-code-mode-host` |
| 搜索 | `rg.exe`（ripgrep） |
| 计算机使用 | `cua_node/`（Computer Use Agent 节点） |
| 其它 | `plugins/`（插件）、`skills/`（技能包）、`native/`、`accessibility/`、`default_app/` |

---

## 2. 主窗口总览（真实文字）

```text
┌──────────────────────────────────────────────────────────────────────────┐
│ 窗口标题: ChatGPT                                             [最小化][恢复][关闭] │
├──────────────────────────────────────────────────────────────────────────┤
│ 顶栏:  [Hide sidebar] [Back] [Forward]  File  Edit  View  Help           │
├─────────────┬───────────────────────────────────────────┬────────────────┤
│ 左侧栏 275px │ 对话区（中央 1000px）                       │ 右侧面板 666px  │
│ Switch mode, │ 核对安卓更新日志版本号   [Chat actions]     │ Review tab …    │
│ current mode:│ [Open in] [⋯] [Toggle summary]            │ Last Turn +255  │
│ Codex [Search]│ 消息流（用户 / ChatGPT / 工具调用卡片）     │ 文件 diff …      │
│ New chat      │                                           │                │
│ Pull requests│                                           │                │
│ Scheduled     │                                           │                │
│ Plugins       │                                           │                │
│ Projects      │                                           │                │
│  ▸ 项目列表    │                                           │                │
│ Recents:      │                                           │                │
│  No chats     │                                           │                │
│ [Open profile│                                           │                │
│  menu] deepseek │ 输入区: [＋] [🎙] Do anything [模型▾] [Stop]│                │
├─────────────┴───────────────────────────────────────────┴────────────────┤
│ 窗口外右下角还有两个浮层窗口: Activity notifications（活动通知）、Codex pet（宠物）│
└──────────────────────────────────────────────────────────────────────────┘
```

---

## 3. 页面图解

### 3.1 对话页（主页面，当前线程）

```text
┌──────────────────────────────────────────────────────────────────────────┐
│ [Hide sidebar] [Back] [Forward]  File Edit View Help                     │
├─────────────┬───────────────────────────────────────────┬────────────────┤
│ Switch mode,│ 核对安卓更新日志版本号                       │ Review [×]     │
│ current mode│ [Chat actions] [Open in] [⋯] [Toggle        │ [Open side     │
│ : Codex     │  summary]                                  │  panel tab]    │
│ [Search]    ├───────────────────────────────────────────┤ [Expand panel] │
│ New chat    │ 消息流（向下滚动，见 3.5）：                 │ Last Turn      │
│ Pull        │  · You said: / ChatGPT said:               │ +255 -0        │
│ requests    │  · Worked for … 运行时长徽章                │ [Review        │
│ Scheduled   │  · Review changed files 卡片                │  options]      │
│ Plugins     │  · Edited <文件名> +N -M   [Undo] [Review]  │ [Collapse all  │
│ Projects    │  · 工具调用卡片 Ran commands / Running…     │  diffs]        │
│  项目列表    │  · 文件/文档卡片（可点击打开）               │ [Jump to file] │
│ Recents     │                                            │ [Switch to     │
│  No chats   │                                            │  unified diff] │
│ [profile]   │                                            │ [Show files]   │
│ deepseek    │                                            │ [Commit or     │
│ [help]      │                                            │  push] [⋯]     │
│             │                                            │ Codex 桌面应用… │
│             │                                            │ .md  +255 -0   │
│             │                                            │ [Copy path]    │
│             │                                            │ [Toggle file   │
│             │                                            │  diff] [Open in]│
│             ├───────────────────────────────────────────┤                │
│             │ [Add files and more] [🎙] Do anything       │                │
│             │            [DeepSeek-V4-Flash] [Stop]       │                │
└─────────────┴───────────────────────────────────────────┴────────────────┘
```

顶栏（窗口菜单栏下方）真实文字：`Hide sidebar`、`Back`、`Forward`、`File`、`Edit`、`View`、`Help`。

对话区顶部栏真实文字：当前对话标题 `核对安卓更新日志版本号`，右侧按钮：`Chat actions`、`Open in`、`Secondary action`、`Toggle summary`。

输入区真实文字：按钮 `Add files and more`、模型按钮 `DeepSeek-V4-Flash`、`Stop`；输入框占位文字 **`Do anything`**。

---

### 3.2 左侧栏（真实文字）

```text
┌─────────────────────────────┐
│ Switch mode, current mode:  │
│ Codex          [Search]      │
│ [New chat]                  │
│ [Pull requests]             │
│ [Scheduled]                 │
│ [Plugins]                   │
│ Projects      [▣] [＋]       │
│ ┌─────────────────────────┐ │
│ │ WordToWorld            │ │
│ │  通读项目并制定多平台开发规划 │ │
│ │ SugarPaper             │ │
│ │  核对安卓更新日志版本号    │ │
│ │  官网开发               │ │
│ │  多版本并行开发          │ │
│ │  GitHub Releases提交     │ │
│ │  添加源码版权声明        │ │
│ │  Android开发            │ │
│ │  Windows开发            │ │
│ │  仿照参考网址重设网页与安卓 │ │
│ │  风格                  │ │
│ │  Web开发                │ │
│ └─────────────────────────┘ │
│ Recents     [▣] [＋]         │
│  No chats                   │
│ ─────────────────────────── │
│ [Open profile menu]         │
│ deepseek      [Open help    │
│               menu]         │
└─────────────────────────────┘
```

说明（来自 UIA 树，非提炼）：左侧栏结构名称为 `Scheduled task folders`；每个项目下列表名为 `Scheduled tasks in <项目名>`；每条对话有 `Pin chat`（固定）和 `Archive chat`（归档）按钮；底部个人菜单显示用户名 `deepseek`。

---

### 3.3 右侧 Review 面板（真实文字）

```text
┌────────────────────────────────┐
│ Review [×]  [Open side panel   │
│ tab]              [Expand panel]│
├────────────────────────────────┤
│ Last Turn      +255   -0       │
│ [Review options] [Collapse all │
│ diffs] [Jump to file] [Switch  │
│ to unified diff] [Show files]  │
│ [Commit or push] [More Git     │
│ actions]                       │
│ ┌────────────────────────────┐ │
│ │ Codex 桌面应用技术解析与页面图解.md │
│ │ +255  -0  [Copy path]      │ │
│ │ [Toggle file diff] [Open in]│ │
│ │ …diff 内容…                │ │
│ └────────────────────────────┘ │
└────────────────────────────────┘
```

---

### 3.4 右侧 Git / 来源面板（真实文字）

当前对话右侧还有一块上下文面板（Environment / Git 状态 / Sources），文字如下：

```text
Environment            [Set up local environment]
[Changes]
[Local]
[main]
[Commit or push]
Sources                 [Attach files or connect apps]
  github.com/HelloXiYangyang/SugarPaper/releases
  Web search
[View all]
```

---

### 3.5 消息流（对话内卡片，真实文字）

消息流中出现的实际控件文字（示例）：

- 用户消息前缀：`You said:`
- 助手消息前缀：`ChatGPT said:`
- 运行时长徽章：`Worked for 1m 49s` / `Worked for 2分钟 11秒` / `Working for 4分钟 7秒` / `Working…`
- 工具调用卡片：`Ran commands` / `Running command for 5s` / `Ran Add-Type -AssemblyName …`
- 文件变更卡片：`Review changed files`、`Edited README.md  +24  -55`、`Edited Codex 桌面应用技术解析与页面图解.md  +255  -0`、按钮 `Undo`、`Review`
- 消息操作按钮：`Copy message`、`Continue in new chat from here`、时间戳如 `2:23`
- 代码块按钮：`Enable word wrap`、`Copy`

---

### 3.6 Pull requests 页

```text
┌──────────────────────────────────────────────┐
│ Pull requests                                │
├──────────────────────────────────────────────┤
│                                              │
│   Checking GitHub access                     │
│                                              │
└──────────────────────────────────────────────┘
```

页面真实文字：标题 `Pull requests`，正文状态 `Checking GitHub access`（点击后正在检查 GitHub 访问权限，无列表内容）。

---

### 3.7 Scheduled（定时任务）页

```text
┌──────────────────────────────────────────────────────────────┐
│                                        [Create] [Create      │
│                                         scheduled task       │
│                                         options]             │
├──────────────────────────────────────────────────────────────┤
│ Scheduled tasks                                              │
│ Ask ChatGPT to schedule tasks, set reminders, or monitor for │
│ updates                                                      │
│ [🔍] Search scheduled tasks                                  │
│                                                              │
│ Suggestions                                                  │
│ ┌──────────────────────────────────────────────────────────┐ │
│ │ [＋] Daily brief        Weekdays at 8:00                 │ │
│ │      Start each weekday with a summary of your calendar, │ │
│ │      unread email, and priorities                        │ │
│ │ [＋] Weekly review      Fridays at 16:00                 │ │
│ │      Turn your recent work into a concise status update  │ │
│ │      every Friday                                        │ │
│ │ [＋] Follow-up monitor  Weekdays at 9:00                 │ │
│ │      Review recent email and calendar activity and flag  │ │
│ │      anything that needs your attention                  │ │
│ └──────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────┘
```

按钮真实文字：`Create`、`Create scheduled task options`；搜索框 `Search scheduled tasks`；建议卡片 `Daily brief` / `Weekly review` / `Follow-up monitor`，各带 `Add … scheduled task` 按钮（+）。

---

### 3.8 Plugins（插件）页

```text
┌──────────────────────────────────────────────────────────────┐
│ [Plugins] [Skills]                        [Refresh] [Manage] │
│                                        [Add]                │
├──────────────────────────────────────────────────────────────┤
│ Plugins                                                      │
│ Work with ChatGPT across your favorite tools                 │
│ [🔍] Search plugins                                          │
│                                                              │
│ Installed                              [Manage]              │
│ [Documents] [PDF] [Spreadsheets] [Presentations]             │
│ [Template Creator]                                          │
│                                                              │
│ Plugin directory                    [Filter sections]        │
│ [Public] [Personal]                                          │
│                                                              │
│ Featured                                                      │
│ [Spreadsheets]  Spreadsheets       [Presentations]  Pre…     │
│  Create and edit spreadsheet files  Create and edit …        │
│                                                              │
│ Productivity                                                  │
│ [Documents] [PDF] [Spreadsheets] [Presentations]             │
│ [Template Creator]                                           │
│                                                              │
│ More plugins coming soon                                     │
└──────────────────────────────────────────────────────────────┘
```

页面真实文字：顶部标签组 `Browse plugins or skills`（`Plugins` / `Skills`），标题 `Plugins`，副标题 `Work with ChatGPT across your favorite tools`，搜索框 `Search plugins`；分组 `Installed`（Documents、PDF、Spreadsheets、Presentations、Template Creator）、`Plugin directory`（Public / Personal）、`Featured`、`Productivity`；卡片描述如 `Create and edit spreadsheet files`、`Read, create, and verify PDF files`、`Create and edit document artifacts`、`Create or update reusable templates from reference content`；底部 `More plugins coming soon`。

---

### 3.9 Command menu（搜索 / 命令面板）

按侧边栏 `Search` 打开的浮层窗口（标题 `Command menu`，提示 `Search commands and past chats.`）：

```text
┌────────────────────────────────────────────────┐
│ Command menu                                  │
│ Search commands and past chats.               │
│ [搜索输入框]                                   │
├────────────────────────────────────────────────┤
│ Unread chats                                  │
│   核对安卓更新日志版本号  SugarPaper            │
│   官网开发  SugarPaper                        │
│ Chats                                        │
│   核对安卓更新日志版本号  SugarPaper  Ctrl+1   │
│   官网开发  SugarPaper  Ctrl+2                │
│   多版本并行开发  SugarPaper  Ctrl+3           │
│   GitHub Releases提交  SugarPaper  Ctrl+4     │
│   添加源码版权声明  SugarPaper  Ctrl+5         │
│   Android开发  SugarPaper  Ctrl+6             │
│   Windows开发  SugarPaper  Ctrl+7             │
│   通读项目并制定多平台开发规划  WordToWorld Ctrl+8│
│   仿照参考网址重设网页与安卓风格  SugarPaper Ctrl+9│
│ Suggested                                     │
│   New chat  Ctrl+N                            │
│   Open folder  Ctrl+O                         │
│ Settings                                     │
│   General / Appearance / Pets / Git /         │
│   Environments / Worktrees / Configuration /  │
│   Personalization / Keyboard shortcuts /      │
│   Browser / Computer use / MCP servers /      │
│   Hooks / Plugins / Archived chats / Account  │
│ Chat                                          │
│   New standalone chat  Ctrl+Alt+O             │
│   Archive chat  Ctrl+Shift+A                  │
│   Toggle pin  Ctrl+Alt+P                      │
│ Navigation                                   │
│   Switch chat…  / Previous chat Ctrl+Shift+[  │
│   Next chat Ctrl+Shift+]  / Switch to Work    │
│   Alt+2  / Switch to Codex Alt+3  / Find      │
│   Ctrl+F  / Back Ctrl+[  / Forward Ctrl+]     │
│ Panels                                       │
│   Toggle sidebar Ctrl+B  / Toggle bottom      │
│   panel Ctrl+J  / Open terminal Ctrl+`  /     │
│   Open browser tab Ctrl+T  / Toggle browser   │
│   panel Ctrl+Shift+B  / Toggle Review panel   │
│   Ctrl+Alt+B                                  │
│ Skills                                       │
│   Force reload skills  / Go to skills         │
│ Configure                                    │
│   Theme Codex  / Import from other AI apps    │
│ App                                          │
│   Hide pet  / Clear all unreads Shift+Escape  │
│   / Manage scheduled tasks  / Feedback        │
└────────────────────────────────────────────────┘
```

---

### 3.10 设置页（左侧设置导航，真实文字）

```text
┌─────────────────────────────┐
│ [Back to app]               │
│ [🔍] Search settings        │
│ Personal                    │
│  [General]                  │
│  [Appearance]               │
│  [Configuration]            │
│  [Personalization]          │
│  [Pets]                     │
│  [Keyboard shortcuts]       │
│  [Account]                  │
│ Integrations                │
│  [Plugins]                  │
│  [Browser]                  │
│  [Computer use]             │
│ Coding                      │
│  [Hooks]                    │
│  [Git]                      │
│  [Environments]             │
│  [Worktrees]                │
│ Archived                    │
│  [Archived chats]           │
└─────────────────────────────┘
```

---

### 3.11 设置 → General（真实文字）

```text
General
──────
Permissions
  Default permissions
  By default, ChatGPT can read and edit files in its workspace. It
  can ask for additional access when needed
  [Default permissions are always shown]      ← 开关
  Full access
  When ChatGPT runs with full access, it can edit any file on your
  computer and run commands with network, without your approval.
  This significantly increases the risk of data loss, leaks, or
  unexpected behavior.
  Learn more about elevated risks.
  [Show Full access in the composer]          ← 开关

General
  Default file open destination
  Where files and folders open by default
  [VS Code ▾]
  Integrated terminal shell
  Choose which shell opens in the integrated terminal.
  [PowerShell]
  Language
  Language for the app UI
  [简体中文 ▾]
  Bottom panel
  Show the bottom panel control in the app header
  [Bottom panel]                              ← 开关
  Import work from other AI apps
  Bring over your setup, projects, and recent chats
  [No data detected]
  Open source licenses
  Third-party notices for bundled dependencies
  [View]
  Plugins
  Allow ChatGPT to use installed plugins
  [Toggle plugins]                            ← 开关

Composer
  Show context window usage
  [Show context window usage in the composer] ← 开关
  Send shortcut
  Choose when Enter sends a prompt or inserts a new line
  [Enter ▾]
  Follow-up behavior
  Queue follow-ups while ChatGPT runs or steer the current run.
  Press Ctrl+⏎ to do the opposite for one message
  [Queue] [Steer]

Notifications
  Turn completion notifications
  Set when ChatGPT alerts you that it's finished
  [Only when unfocused ▾]
  Enable permission notifications
  Show alerts when notification permissions are required
  [Enable permission notifications]           ← 开关
  Enable question notifications
  Show alerts when input is needed to continue
  [Enable question notifications]             ← 开关
```

---

### 3.12 设置 → Appearance（真实文字）

```text
Appearance
Theme
  [Light theme ▾ / Dark theme ▾]（主题切换）
  Light theme:
    Accent / Background / Foreground
    UI font / Code font
    Translucent sidebar
    Contrast
  Dark theme:
    Accent / Background / Foreground
    UI font / Code font
    Translucent sidebar
    Contrast
Preferences
  Use pointer cursors
  Change the cursor to a pointer when hovering over interactive
  elements
  Reduce motion
  Reduce animations or match your system
  UI font size
  Adjust the base size used for the ChatGPT UI
  Code font size
  Adjust the base size used for code across chats and diffs
  Diff markers
  Show changes using colors or +/− markers
```

---

### 3.13 设置 → Configuration（真实文字）

```text
Configuration
Configure permissions, web access, and agent responses for new chats

Agent defaults
  [User config]（配置文件选择）
  Approval policy
  Choose when ChatGPT asks for approval
  Sandbox settings
  Choose how much ChatGPT can do when running commands
  Web search
  Choose how ChatGPT accesses the web
  Output detail
  Choose how much detail ChatGPT includes in responses
  Reasoning summary
  Choose how ChatGPT summarizes its reasoning
```

---

### 3.14 设置 → Personalization（真实文字）

```text
Personalization
Custom instructions
Give ChatGPT extra instructions and context for all chats on this
host.
[多行输入框 Custom instructions]

Memory
Configure how local memories are collected, retained, and
consolidated on this computer.
  Enable local memories
  Create memories from chats on this computer and use them to
  personalize future chats on this computer
  Allow local memory generation from tool-assisted chats
  Generate memories from chats that used MCP tools or web search
  Delete local memories
  Delete all memories stored locally on this computer

Personality
  Choose a default tone for ChatGPT responses
```

---

### 3.15 设置 → Pets（真实文字）

```text
Pets
Pick a pet
Pets manage threads and surface what needs attention
（宠物选择区）
Custom pets
C:\Users\xyy20\.codex\pets
```

---

### 3.16 设置 → Keyboard shortcuts（真实文字，完整列表）

```text
Keyboard shortcuts
[🔍] Search keyboard shortcuts

New chat                        Ctrl+N
  Start a new chat
Temporary chat                  Ctrl+Shift+N
  Start a chat that won't appear in history
Quick chat                      Ctrl+Alt+N
  Start a lightweight chat in the quick composer
Archive chat                    Ctrl+Shift+A
  Archive the current chat
New standalone chat             Ctrl+Alt+O
  Start a new chat outside of any project
Open side chat                  Ctrl+Alt+S
  Open the current chat in a side chat
Open in new window              Unassigned
  Open the current chat in a new window
Toggle pin                      Ctrl+Alt+P
  Pin or unpin the current chat
Focus browser address bar       Ctrl+L
  Focus the in-app browser address bar
Go to line                      Ctrl+L
  Go to a line in the current file
Back                            Ctrl+[   / Mouse Back
  Go back in navigation history
Forward                         Ctrl+]   / Mouse Forward
  Go forward in navigation history
Next recently viewed chat       Ctrl+Tab
  Cycle to the next recently viewed chat
Next tab                        Ctrl+Shift+] / Ctrl+PageDown
  Switch to the next tab
Next chat                       Ctrl+Shift+] / Ctrl+PageDown
  Switch to the next chat
Previous recently viewed chat   Ctrl+Shift+Tab
  Cycle to the previous recently viewed chat
Previous tab                    Ctrl+Shift+[ / Ctrl+PageUp
  Switch to the previous tab
Previous chat                   Ctrl+Shift+[ / Ctrl+PageUp
  Switch to the previous chat
Switch chat…                    Unassigned
  Search and switch to a chat
Switch to Work                  Alt+2
Switch to Codex                 Alt+3
Open browser tab                Ctrl+T
  Open a new browser tab
Open review tab                 Ctrl+Shift+G
  Open the review tab
Toggle bottom panel             Ctrl+J
  Show or hide the bottom panel
Toggle browser panel            Ctrl+Shift+B
  Show or hide the browser panel
Toggle pinned summary           Unassigned
  Show or hide the pinned summary
Toggle review                   Unassigned
  Show or hide Review for the current Git-backed chat
Toggle sidebar                  Ctrl+B
  Show or hide the sidebar
Toggle Review panel             Ctrl+Alt+B
  Show or hide Review for the current chat
Open terminal                   Ctrl+`
  Open the terminal panel
Environment action 1            Shift+Win+D
  Run the environment action in this shortcut slot
Environment action 2 … 7        Unassigned
  Run the environment action in this shortcut slot
```

> 说明：快捷键页面很长，以上为按 UIA 元素顺序整理的全部可见条目；`Ctrl+L` 同时出现在“Focus browser address bar”和“Go to line”两条（界面原样如此）。

---

### 3.17 设置 → Browser（真实文字）

```text
Browser
General
  Web URL and link open destination
  [Default browser ▾]
  Where links open by default
  Local URL open destination
  [ChatGPT ▾]
  Where local development sites open by default
Browsing data
  [Clear all browsing data] [Show individual browsing data options]
  Clear browsing history, site data, cache, and download history
  from the in-app browser
Annotation screenshots
  [Always include ▾]
  Screenshots help ChatGPT better understand and address comments,
  but increase plan usage
Autofill and passwords
  Password manager              [Manage]
  Add, delete, and edit saved passwords
  Contact info                  [Manage]
  Add, delete, and edit saved addresses, phone numbers, and email
  addresses
Downloads
  Location                     [Change]
  System Downloads folder
  Ask where to save downloads  [Ask where to save downloads]
  Show a save dialog for downloads you start in the built-in browser
  Download history              [Manage download history]
  View and manage files downloaded from the built-in browser
Permissions
  Site settings                 [Manage]
  Control camera and microphone permissions in the built-in browser
```

---

### 3.18 设置 → Computer use（真实文字）

```text
Computer use
Manage how ChatGPT uses other applications on your computer
Control
  Google Chrome
  [Unavailable plugin toggle]（不可用，开关置灰）
  Disabled by your organization or unavailable in your region
  Microsoft Edge
  [Unavailable plugin toggle]（不可用，开关置灰）
  Disabled by your organization or unavailable in your region
```

---

### 3.19 设置 → Hooks（真实文字）

```text
Hooks              [Reload hooks]
Manage lifecycle hooks from config and enabled plugins.
No hooks found
Configured hooks will appear here
```

---

### 3.20 设置 → Git（真实文字）

```text
Git
Branch prefix
  Prefix used when ChatGPT creates new branches
  [Always force push]
  Use --force-with-lease when pushing from ChatGPT
  [Create draft pull requests]
  Use draft pull requests by default when creating PRs from ChatGPT
Review delivery    [Inline] [Detached]
  Start /review in the current chat when possible or launch a
  separate review chat
Commit instructions           [Save]
  Added to commit message generation prompts
Pull request instructions     [Save]
  Added to PR title/description generation prompts
```

---

### 3.21 设置 → Environments（真实文字）

```text
Environments
Local environments tell ChatGPT how to set up worktrees for a
project.
[Add project]  Select a project
[Add environment to WordToWorld]
[Add environment to SugarPaper]
  HelloXiYangyang
```

---

### 3.22 设置 → Worktrees（真实文字）

```text
Worktrees
Worktree root
  Directory where ChatGPT creates managed worktrees; leave blank to
  use the default location
Automatically delete old worktrees  [Automatically delete old
worktrees]
  Recommended for most users. Turn this off only if you want to
  manage old worktrees and disk usage yourself.
Auto-delete limit
  Number of managed worktrees to keep before older ones are pruned
  automatically. ChatGPT snapshots worktrees before deleting, so
  pruned worktrees should always be restorable.
[Refresh]
No worktrees yet
Worktrees created by ChatGPT will appear here
```

---

### 3.23 设置 → Archived chats（真实文字）

```text
Archived chats
Loading archived chats…
```

> 本机点击该页时处于加载状态，仅显示以上文字。

---

### 3.24 设置 → Account（未捕获，如实说明）

本机多次尝试点击 `Account` 设置项，界面均未响应（该入口存在于设置侧栏与命令面板中）。此页未捕获到真实界面文字，不做编造。应用资源内显示该页属于 usage/plan 相关路由（含 plan、subscription、billing 等文本键）。

---

### 3.25 活动通知 / Codex 宠物（右下角浮层窗口）

```text
┌──────────────────────────────┐
│ Activity notifications       │
│ ┌──────────────────────────┐ │
│ │ [官网开发] Running 通知内容 │ │
│ │ [Reply to 官网开发] [Dismiss]│ │
│ └──────────────────────────┘ │
│ ┌──────────────────────────┐ │
│ │ [核对安卓更新日志版本号]    │ │
│ │ Running                  │ │
│ │ [Expand] [Reply] [Dismiss]│ │
│ └──────────────────────────┘ │
└──────────────────────────────┘

┌────────────────┐
│ Codex pet      │
│ [Collapse      │
│  activity]     │
│ （宠物）        │
│ [Resize pet]   │
└────────────────┘
```

真实文字：`Activity notifications`；通知项 `官网开发`（状态 `Running`）、`核对安卓更新日志版本号`（状态 `Running`）；按钮 `Open notification`、`Reply to …`、`Dismiss`、`Expand`；宠物面板标题 `Codex pet`，按钮 `Collapse activity`、`Resize pet`。

---

## 4. 页面逻辑（每页一句话，基于实测）

| 页面 | 逻辑 |
| :--- | :--- |
| 对话页 | 左侧选项目/对话 → 中央看消息流与工具卡片 → 右侧看 diff/来源，底部输入框发指令 |
| 左侧栏 | 项目分组（`Scheduled tasks in <项目>`），每条对话可固定/归档；Recents 区为空时显示 `No chats` |
| Review 面板 | 列出本回合文件变更（`Last Turn +N -M`），可逐文件查看 diff、复制路径、打开文件、提交 |
| 环境/来源面板 | 显示本地环境入口、Git 状态（Changes/Local/main）、当前引用来源（GitHub Releases、Web search） |
| Pull requests | 进入即检查 GitHub 访问权限，无数据时只有状态文字 |
| Scheduled | 提供模板建议（Daily brief 等），可搜索、可 `Create` 新建定时任务 |
| Plugins | 按 Installed / Featured / Productivity 分区展示插件卡片，可搜索、Refresh、Manage、Add |
| Command menu | 一个面板集中所有命令与历史对话，分组列出并带快捷键，可直接跳转设置 |
| 设置 | 左侧分类导航，右侧对应设置项；General 管权限/语言/终端/通知，其余各页管外观、Git、环境等 |

---

## 5. 页面风格（实测观察）

1. **三栏 IDE 式布局**：左侧项目/对话树 + 中央对话流 + 右侧 Review/上下文面板。
2. **极简顶栏**：Hide sidebar / Back / Forward + 原生菜单 File Edit View Help，无多余装饰。
3. **消息卡片化**：用户/助手消息、工具调用（`Ran commands`）、文件变更（`Review changed files`）都是可展开卡片，带时长徽章和 Undo/Review 按钮。
4. **右侧面板可切换**：Review 标签页 + 环境/Git/来源区块，可 Expand / 切换 unified diff / 显示文件。
5. **命令面板驱动**：所有设置与动作都能在 Command menu 里按名称搜索并带快捷键执行。
6. **设置分类清晰**：Personal / Integrations / Coding / Archived 四组，搜索框可过滤。
7. **浮层小窗**：活动通知与 Codex 宠物作为独立小窗常驻右下角。

---

## 6. 数据来源与说明

- 所有文字来自本机运行窗口的 UI Automation 树（`AutomationElement.Current.Name`），即屏幕实际显示文字；坐标来自 `BoundingRectangle`（已换算为逻辑像素）。
- 图标/装饰（按钮图形）以 `[▣]`、`[🔍]` 等占位表示，不编造图标内容。
- `Account` 设置页未能通过界面进入，已如实标注"未捕获"；其余页面均为本机实测。
- 对话内容（项目名、对话标题、消息）来自用户真实使用数据，仅作演示界面结构之用。
