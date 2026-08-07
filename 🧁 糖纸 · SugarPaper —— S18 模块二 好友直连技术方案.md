# 🧁 糖纸 · SugarPaper —— S18 模块二：好友直连技术方案

> 版本：v1.0.0（2026-08-08）
> 目标：不同账号之间「加好友 + 端到端加密消息 + 分享作业」，完全去中心化（无中心服务器，复用 Nostr 中继 + 现有加密基础设施）。
> 原则：零新依赖、离线优先、中继只见密文；MVP 先走中继转发，WebRTC 直连为后续增强。

---

## 1. 总体架构

```
用户 A ──(AES-GCM 密文 + Ed25519 签名)──> Nostr 中继 ──> 用户 B
         （中继只存储转发密文，无法解密）                    （B 用共享密钥解密）
```

- 身份：现有 Ed25519 公钥（助记词派生），无需新账号。
- 传输：Nostr 自定义事件（kind 19324，d-tag `sugarpaper:friend`，p-tag 指向接收方）。
- 加密：**预共享对称密钥**（好友邀请时交换，AES-256-GCM，复用 `account.encryptData/decryptData`，密钥 = `sha256(friendKey)`）。
- 签名：Ed25519 签名事件，防伪造发送者。

## 2. 加好友（预共享密钥模式）

### 2.1 邀请生成（A）

A 点击「生成邀请」：

1. 生成随机 32 字节 `friendKey`（浏览器 `crypto.getRandomValues`）。
2. 邀请文本：

```
sugarpaper://friend?v=1&name=<A昵称>&pub=<A的pubkey(hex)>&key=<friendKey(b64url)>
```

3. 展示为文本 + 二维码（可直接复制/截图分享）。

### 2.2 邀请导入（B）

B 粘贴邀请文本（或扫码）→ 校验格式与公钥 → 存入好友列表（昵称 / 对方 pubkey / 共享 friendKey）。

> 说明：预共享密钥只在两端出现（A 生成后直接展示，B 粘贴导入），不经过中继；中继上的消息只有密文。后续可升级为 X25519（Ed25519→X25519）免手动交换，作为增强版。

### 2.3 好友记录（本地存储，独立于同步快照）

```json
{
  "id": "uuid",
  "pubkey": "<hex>",
  "name": "昵称",
  "note": "备注",
  "friendKey": "<b64url>",
  "addedAt": "ISO",
  "lastMsgAt": "ISO | null"
}
```

存储：网页版 `localStorage`（`sugarpaper:friends`）；安卓独立 JSON 文件（后续实现）。

## 3. 加密消息协议

### 3.1 消息信封（加密后）

```json
{
  "v": 1,
  "type": "msg | share-task | friend-req",
  "ts": "ISO",
  "payload": { "iv": "<b64url>", "data": "<b64url 密文>" }
}
```

payload 明文（加密前）：

- `msg`：`{ "text": "你好" }`
- `share-task`：`{ "task": { ...任务字段... } }`
- `friend-req`：`{ "pub": "<hex>" }`（单方面请求，确认后互为好友）

### 3.2 Nostr 事件

```json
{
  "kind": 19324,
  "created_at": 0,
  "tags": [["d", "sugarpaper:friend"], ["p", "<接收方pubkey hex>"]],
  "content": "<信封 JSON>",
  "pubkey": "<发送方 hex>",
  "id": "...",
  "sig": "Ed25519 签名"
}
```

### 3.3 收发流程

- 发送：构建信封 → `account.encryptData` 加密 payload → 构建并签名 Nostr 事件 → 广播到所有已配置中继。
- 接收：订阅 `kinds:[19324], '#p':[自己pubkey]` → 校验签名（发送者必须是好友公钥）→ `account.decryptData` 解密 → 按 type 处理（消息入库 / 弹分享导入）。
- 防骚扰：仅处理 `pubkey ∈ 好友列表` 的事件；未确认的 `friend-req` 仅作请求展示。

## 4. 分享作业

1. 任务卡「分享给好友」→ 选择好友 → `share-task` 信封发送。
2. 对方收到 → 弹确认「收到 xx 分享的作业」→ 导入（`store.addTask`，subject/标题/截止/优先级/图片保留）。
3. 分享出去的副本归接收方本地所有。

## 5. 文件与接口（网页版）

- `web/js/friends.js`：数据与协议层（`S.friends`）
  - `list()` / `addByInvite(text)` / `remove(id)` / `makeInvite()` / `inviteText()`
  - `sendMessage(friendId, text)` / `shareTask(friendId, task)`
  - `init()`（订阅中继，处理来信回调 `onMessage`）
- `web/js/ui-friends.js`：界面层（`S.ui.friends.openPanel()`）
  - 设置页「好友直连」卡片入口
  - 邀请生成（文本 + 复制）/ 邀请导入（粘贴）
  - 好友列表（发送消息 / 分享作业 / 删除）
  - 消息弹窗与来信 Toast
- 安卓端：`app/lib/data/friends_service.dart`（数据 + 加密 + 中继收发），UI 待发布链恢复后接入。

## 6. 测试与验收

- e2e：两个页面经本地 mini-relay 互加好友 → A 发消息 → B 收到并解密显示；A 分享作业 → B 确认导入成功。
- 安全：中继收到的 content 为密文（测试断言不含明文关键词）。
- 隐私：好友列表仅存本机；删除好友即停止接收其事件。

## 7. 版本与范围

- 本次实现：网页版完整闭环（好友 / 加密消息 / 分享作业），安卓数据层同步写好。
- 后续增强（不在本次范围）：WebRTC 直连聊天、X25519 免手动交换、好友间便签/周计划共享、桌面端好友面板。
