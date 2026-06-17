# MailCode 网站设计文档

> 版本: v1.2
> 更新: 2026-05-15
> 状态: ✅ 已实施

---

## 一、概述

### 1.1 项目背景

MailCode 是一个 Python 邮件连接器，通过邮件实现对 AI 助手（OpenCode / Claude Code）的远程操控。项目当前版本 v0.1.7，核心功能包括 IMAP/SMTP 中继、定时任务引擎、会话持久化、终端聊天等。MIT 开源协议，所有功能免费。

### 1.2 改造目标

1. **展示核心功能**：IMAP/SMTP 中继、定时任务、会话持久化、终端聊天、安全防护
2. **专业 SaaS 风格**：简洁现代、卡片布局、大量留白
3. **保留全部 6 种语言**：通过 i18n 框架统一管理

### 1.3 技术选型

| 类别 | 选择 | 说明 |
|------|------|------|
| 框架 | 纯 HTML/CSS/JS | 无需构建步骤，直接部署 |
| 样式 | CSS Custom Properties | 设计系统驱动的 CSS Variables |
| i18n | 多 HTML 目录 | `/lang/index.html` 6种语言独立文件 |
| 部署 | GitHub Pages | `username.github.io/mailcode-site` |
| 图标 | Unicode Emoji / Inline SVG | 零依赖 |
| 动画 | CSS + IntersectionObserver | 原生实现，无第三方库 |
| 字体 | Inter + JetBrains Mono | Google Fonts CDN 加载 |

### 1.4 GitHub Pages 关键限制

GitHub Pages **仅提供静态文件托管**，以下功能不可用（直接影响设计决策）：

| 不可用 | 替代方案 |
|--------|----------|
| 服务端渲染 (SSR) | 纯静态 HTML，所有渲染在浏览器完成 |
| 服务端路由 / 动态路由 | `/[lang]/` 由目录结构实现：`en/index.html`、`zh/index.html` |
| Node.js 中间件 (i18n 重定向) | 浏览器端 JS 检测语言并跳转 (`index.html`) |
| API 路由 | 无后端，第三方服务通过客户端 JS 调用 |
| 构建步骤 / npm 依赖 | 直接在仓库维护 HTML，git push 即部署 |
| SPA 客户端路由 | 多页面模式，每个语言/页面一个 HTML 文件 |

**设计影响总结**：
- 6 种语言 = 6 个 `index.html` + 1 个根跳转页，内容变更需同步修改 7 个文件
- 所有交互（语言切换、复制、标签页）必须用原生 JS 实现
- 无热重载，开发时直接浏览器打开本地文件

---

## 二、设计系统

### 2.1 色彩系统

```css
/* 品牌色 */
--purple-500: #6C5CE7;    /* 主色调 - CTA/链接/高亮 */
--purple-600: #5A4BD1;    /* hover state */
--purple-100: #EDE9FE;    /* 浅紫背景 */

/* 中性色 */
--slate-900: #0F172A;     /* 主标题 */
--slate-800: #1E293B;     /* 次要标题 */
--slate-700: #334155;     /* 正文 */
--slate-500: #64748B;     /* 次要文字 */
--slate-400: #94A3B8;     /* 辅助文字 */
--slate-300: #CBD5E1;     /* 边框 */
--slate-200: #E2E8F0;     /* 浅边框 */
--slate-100: #F1F5F9;     /* 卡片背景 */
--slate-50: #F8FAFC;      /* 页面背景 */
--white: #FFFFFF;          /* 主背景 */

/* 语义色 */
--emerald-500: #10B981;    /* 成功 / Pro 标签 */
--amber-500: #F59E0B;      /* 警告 */
--red-500: #EF4444;        /* 错误 / Danger */
--blue-500: #3B82F6;       /* 信息 */
```

### 2.2 字体系统

```css
/* 主字体 */
font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;

/* 代码字体 */
font-family: 'JetBrains Mono', 'SF Mono', 'Fira Code', monospace;

/* 字号 scale */
text-xs: 12px
text-sm: 14px
text-base: 16px
text-lg: 18px
text-xl: 20px
text-2xl: 24px
text-3xl: 30px
text-4xl: 36px
text-5xl: 48px
text-6xl: 60px
```

### 2.3 间距系统

```css
/* 间距 scale (Tailwind 默认) */
space-1: 4px
space-2: 8px
space-3: 12px
space-4: 16px
space-5: 20px
space-6: 24px
space-8: 32px
space-10: 40px
space-12: 48px
space-16: 64px
space-20: 80px
space-24: 96px
```

### 2.4 圆角系统

```css
--radius-sm: 6px;
--radius-md: 12px;
--radius-lg: 16px;
--radius-xl: 24px;
--radius-full: 9999px;
```

### 2.5 阴影系统

```css
/* 卡片阴影 */
shadow-sm: 0 1px 2px 0 rgb(0 0 0 / 0.05);
shadow-md: 0 4px 6px -1px rgb(0 0 0 / 0.1);
shadow-lg: 0 10px 15px -3px rgb(0 0 0 / 0.1);

/* 按钮阴影 */
shadow-primary: 0 4px 14px 0 rgb(108 92 231 / 0.4);
```

---

## 三、页面结构

### 3.1 路由设计

```
/                           # 重定向到 /en
/[lang]/                    # 首页 (en/zh/ja/ko/fr/de)
/[lang]/docs               # 文档入口
/[lang]/changelog          # 更新日志
/[lang]/download           # 下载页面
```

### 3.2 首页区块

| 区块 | ID | 内容 |
|------|-----|------|
| Navigation | `#nav` | Logo + 导航 + 语言切换 + CTA |
| Hero + Badges | `#hero` | 标题 + 描述 + 安装命令 + CTA + GitHub Badges |
| Subscribe | `#subscribe` | 邮件订阅（Formspree + 本地反馈） |
| Features | `#features` | 6 大特性网格 |
| How It Works | `#how-it-works` | 4 步流程图 |
| Dual Mode | `#dual-mode` | Reply vs Cold Start 对比 |
| Use Cases | `#use-cases` | 3 场景卡片 |
| Pricing | `#pricing` | 开源展示 |
| CTA | `#cta` | 最终行动召唤 |
| Footer | `#footer` | 链接 + 社交 + 版权 |

### 新增区块说明（v0.3.0）

| 区块 | 实现方式 |
|------|---------|
| GitHub Badges | shields.io 静态徽章，嵌入 Hero 下方，展示 Stars / Downloads / License / Version |
| Analytics | GoatCounter（免费/开源/隐私友好），HTML 注释占位，用户注册后取消注释即可启用 |
| Subscribe | Web3Forms 表单（免费 250条/月），带输入验证、加载态、成功反馈 |

---

## 四、组件设计

### 4.1 Button

**变体 (variants)**:
- `primary`: 紫色背景 (#6C5CE7)，白色文字，圆角 8px
- `secondary`: 白色背景，紫色边框，紫色文字
- `ghost`: 透明背景，hover 时显示浅紫背景
- `link`: 无背景，紫色文字，下划线

**尺寸 (sizes)**:
- `sm`: h-8 px-3 text-sm
- `md`: h-10 px-4 text-base
- `lg`: h-12 px-6 text-lg

**状态**:
- Default / Hover (darken 10%) / Active (darken 15%) / Disabled (opacity 50%)
- Loading: 显示 spinner，禁用点击

**示例**:
```html
<a href="#install" class="btn btn-primary">快速开始</a>
<a href="#" class="btn btn-secondary">查看文档</a>
<button class="btn btn-ghost">了解更多</button>
```

### 4.2 Card

**变体**:
- `default`: 白色背景，轻微阴影
- `elevated`: 更强阴影，hover 时上浮
- `bordered`: 紫色边框

**结构**:
```html
<div class="feature-card">
  <div class="feature-icon">⏰</div>
  <h3>标题</h3>
  <p>内容</p>
</div>
```

### 4.3 Badge

**变体**:
- `default`: 灰色背景
- `success`: 绿色背景 (Pro 标签)
- `warning`: 黄色背景
- `error`: 红色背景
- `pro`: 渐变紫色背景，白色文字 (推荐标签)

**示例**:
```html
<span class="pricing-badge">推荐</span>
<span class="badge">Reply Mode</span>
```

### 4.4 Tabs

用于平台安装命令切换 (macOS / Ubuntu / Fedora / Arch)

**样式**:
- 下划线指示器
- 选中状态：紫色文字 + 紫色下划线
- 未选中：灰色文字

### 4.5 CodeBlock

**样式**:
- 深色背景 (#1E293B)
- JetBrains Mono 字体
- 语法高亮
- 右上角 Copy 按钮

**状态**:
- Default / Copied (显示 "Copied!" 2s)

### 4.6 FeatureCard

**样式**:
- 白色背景
- 左侧图标 (Lucide)
- 标题 + 描述
- hover 时上浮 + 边框变紫

### 4.8 Navigation

**样式**:
- 固定顶部
- 毛玻璃效果 (backdrop-blur)
- Logo 左侧
- 导航链接居中
- 语言切换 + CTA 右侧

**响应式**:
- Desktop: 完整显示
- Mobile: 汉堡菜单

### 4.9 Footer

**结构**:
- 左侧: Logo + 一句话描述
- 中间: 链接分组 (产品/资源/公司)
- 右侧: 社交图标
- 底部: 版权信息

### 4.10 LanguageSwitcher

**样式**:
- 下拉菜单
- 当前语言显示国旗/代码
- 6 种语言选项

---

## 五、首页区块详细设计

### 5.1 Hero

**布局**: 居中，单列

**元素**:
```
┌─────────────────────────────────────────────────────┐
│                                                     │
│  ✉️ MailCode                                         │
│                                                     │
│  Control AI Agents via Email                       │
│                                                     │
│  将你的邮件收件箱变成 AI Agent 的远程控制台。       │
│  支持 OpenCode / Claude Code，通过邮件指令执行任务。 │
│                                                     │
│  ┌─────────────────────────────────────────────┐   │
│  │  curl -fsSL .../install.sh | bash | Copy   │   │
│  └─────────────────────────────────────────────┘   │
│                                                     │
│  [ 快速开始 ]          [ 查看文档 ]                  │
│                                                     │
└─────────────────────────────────────────────────────┘
```

**动画**:
- 标题: 打字机效果 (可选)
- 安装命令: 浅紫色背景脉冲

### 5.2 (已移除 — 社交证明区块)

原社交证明区块（GitHub Stars / 下载量 / 活跃用户）已移除，改为直接由 Features 区块承接。

### 5.3 Features (v0.2.0 重点)

**布局**: 3x2 网格

**元素**:
| 特性 | 图标 | 标题 | 描述 |
|------|------|------|------|
| ⏰ 定时任务 | Clock | 定时任务引擎 | cron 表达式调度，邮件触发 AI 自动执行任务 |
| 💬 终端聊天 | Message | 终端聊天 | 直接启动 REPL 与 AI 对话，无需经过邮件 |
| 📁 会话持久化 | Folder | 会话持久化 | 独立文件存储，跨 serve/chat 模式恢复，粘性 cwd |
| 🛡️ 安全 | Shield | 多重安全防护 | DKIM/SPF + 白名单 + 命令黑名单 + 自动过期 |
| ⚡ 双模式 | Zap | Session + 无状态 | 多轮会话 vs 单次命令，cwd 粘性切换 |
| 🌐 多邮箱 | Mail | 主流邮箱支持 | Gmail / Outlook / QQ 邮箱 / 126 邮箱 |

**卡片样式**:
```
┌─────────────────────────────┐
│  ⏰                          │
│  定时任务引擎                │
│                             │
│  cron 表达式调度，邮件触发   │
│  AI 自动执行任务，支持标准   │
│  cron 格式。                 │
│                             │
│  例: 0 9 * * * 每日早九点    │
└─────────────────────────────┘
```

### 5.4 How It Works

**布局**: 4 步水平流程

**元素**:
```
┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
│  Step 1 │ -> │  Step 2 │ -> │  Step 3 │ -> │  Step 4 │
│         │    │         │    │         │    │         │
│  发送   │    │  IMAP   │    │   AI    │    │  回复   │
│  邮件   │    │  监听   │    │  处理   │    │  通知   │
└─────────┘    └─────────┘    └─────────┘    └─────────┘
```

### 5.5 Dual Mode

**布局**: 左右对比

**元素**:
```
┌─────────────────────────────┐  ┌─────────────────────────────┐
│  Session Mode               │  │  Stateless Mode             │
│  Session 模式               │  │  无状态模式                  │
├─────────────────────────────┤  ├─────────────────────────────┤
│  1. 按邮件主题分组对话      │  │  1. 每封邮件独立处理         │
│  2. 多轮上下文保持          │  │  2. 不保留对话历史           │
│  3. cwd 粘性（首次设置后    │  │  3. cwd 每次重新解析         │
│     后续重用）              │  │  4. 适合定时任务/简单查询    │
│  4. 支持 serve/chat 互通    │  │                             │
└─────────────────────────────┘  └─────────────────────────────┘
```
```

### 5.6 Use Cases

**布局**: 3 列卡片

**元素**:
| 场景 | 描述 |
|------|------|
| 🚀 移动办公 | 手机发送邮件，随时触发 AI 执行开发任务 |
| ⏰ 定时任务 | 设置 cron 任务，定时自动执行代码审查 |
| 🔗 远程协作 | 通过邮件与 AI Agent 交互，跨设备工作 |

### 5.7 Pricing（开源展示）

**布局**: 单列居中

**元素**:
| 卡片 | 内容 |
|------|------|
| MIT 开源 | 完全免费，所有功能可用：IMAP/SMTP 中继、会话管理、定时任务、终端聊天、安全 |

**说明**: 无付费墙，无商业版——完全 MIT 开源，任何人可自由使用、修改、分发。

### 5.8 CTA

**布局**: 居中

**元素**:
```
┌─────────────────────────────────────────────────────┐
│                                                     │
│  准备好控制你的 AI Agent 了吗？                     │
│                                                     │
│  [ 开始使用 MailCode ]    [ 查看文档 ]              │
│                                                     │
│  免费使用，无忧设置                                  │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### 5.9 Footer

**布局**: 4 列

**元素**:
```
┌──────────┬──────────┬──────────┬──────────┐
│ 产品     │ 资源     │ 公司     │ 法律     │
├──────────┼──────────┼──────────┼──────────┤
│ 功能     │ 文档     │ 关于     │ 隐私政策 │
│ 定价     │ API 参考 │ 博客     │ 服务条款 │
│ Changelog│ GitHub   │ 联系我们 │          │
└──────────┴──────────┴──────────┴──────────┘

© 2024 MailCode. All rights reserved.
```

---

## 六、i18n 设计

### 6.1 翻译结构（GitHub Pages 适配）

由于 GitHub Pages 无服务端 i18n 能力，采用 **目录级多语言** 方案：

```
/               → index.html          # 浏览器 JS 检测语言并 302 跳转
/en/index.html  → 英语版 (主版本)
/zh/index.html  → 中文版
```

> 注意：ja/ko/fr/de 语言页面尚未实现，仅 en 和 zh 有实际 HTML 文件。

**语言跳转逻辑** (`index.html`)：
```js
var lang = navigator.language || navigator.userLanguage || 'en'
var code = lang.split('-')[0]
var supported = { en: true, zh: true }
var target = supported[code] ? '/' + code + '/' : '/en/'
window.location.replace(target)
```

### 6.2 翻译同步规则

1. **以 `en/` 为主版本**，中文版保持结构一致
2. 每次修改 `en/` 后，须同步更新 `zh/`
   - [ ] Nav 菜单项
   - [ ] Hero 标题 & 描述
   - [ ] Features 6 卡片
   - [ ] How It Works 4 步骤
   - [ ] Dual Mode 2 卡片
   - [ ] Use Cases 3 场景
    - [ ] Pricing 开源展示
   - [ ] CTA
   - [ ] Footer

---

## 七、响应式断点（纯 CSS Media Queries）

```css
/* 桌面优先 */
@media (max-width: 1024px) { ... }   /* 平板横屏 + 小屏 */
@media (max-width: 900px) { ... }   /* Pricing 切换单列 */
@media (max-width: 768px) { ... }   /* 手机 */
```

**响应式规则**:
- Navigation: 1024px 以上完整显示，以下汉堡菜单
- Features Grid: 1024px 2列，768px 1列
- Pricing: 900px 以下单列堆叠
- Flow / How It Works: 1024px 2列，768px 1列

---

## 八、动画规范

### 8.1 微交互

| 元素 | 动画 | 时长 |
|------|------|------|
| Button hover | scale(1.02) + shadow 增强 | 150ms |
| Card hover | translateY(-4px) | 200ms |
| Link hover | color 变化 | 150ms |

### 8.2 滚动动画

- 使用 IntersectionObserver
- `.fade-up`: opacity 0->1, translateY 20px->0
- 延迟: 每个元素间隔 100ms

### 8.3 过渡

- 使用 CSS transitions + IntersectionObserver
- 统一使用 `ease-out` 缓动 (0.5s)

---

## 九、技术实现

### 9.1 目录结构（GitHub Pages 适配）

```
mailcode-site/                    # GitHub Pages 仓库根目录
├── index.html                    # 语言自动检测 → 302 跳转
├── design/
│   └── DESIGN.md                 # 本设计文档
├── install.sh                    # 远程安装脚本
├── assets/
│   ├── css/
│   │   └── style.css             # 全局样式 (CSS Variables)
│   ├── js/
│   │   └── main.js               # 原生 JS (无依赖)
│   └── images/
│       └── logo.svg              # 品牌 Logo
├── en/
│   └── index.html                # 英语版首页
├── zh/
│   └── index.html                # 中文版首页
└── .gitignore
```

### 9.2 零依赖原则

本项目 **无 package.json、无构建步骤、无 npm 依赖**。

| 通常做法 | 本方案 |
|----------|--------|
| npm install | ❌ 无需 |
| 构建/打包 | ❌ 无需 |
| 热更新服务器 | ❌ 浏览器直接打开 |
| 部署 CI/CD | ✅ 仅需 git push |

---

## 十、验收标准

### 10.1 功能验收

- [ ] 2 种语言页面均可访问（en/zh）
- [ ] Hero 安装命令可复制
- [ ] 开源定价清晰展示
- [ ] 移动端布局正常
- [ ] 页面加载 < 2s

### 10.2 视觉验收

- [ ] 品牌紫 (#6C5CE7) 作为点缀色
- [ ] Inter 字体正确加载
- [ ] 动画流畅无卡顿
- [ ] 卡片 hover 效果正常

### 10.3 内容验收

- [ ] v0.1.7 核心功能全部展示（中继/定时任务/会话/终端聊天/安全）
- [ ] 定时任务示例正确
- [ ] 无路线图功能（Webhook/TUI/冷启动）的残留提及
- [ ] 定价信息准确
