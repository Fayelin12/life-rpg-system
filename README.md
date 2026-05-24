# 🗺️ 人生开放系统 · Life Open World

<p align="center">
  <img src="https://img.shields.io/badge/version-1.1.0-gold" alt="version">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="license">
  <img src="https://img.shields.io/badge/vanilla-no%20framework-blue" alt="vanilla">
</p>

<p align="center">
  <i>受 <b>艾尔登法环</b> 启发的游戏化人生任务管理器。<br>
  把每一天当作开放世界来探索。</i>
</p>

---

## Why

传统的待办清单很无聊。点掉一个任务就像在表单里打了个勾。

这个项目换了一种思路——**你是一个褪色者**，你的目标、习惯和日常任务变成了分布在版图上的地标、任务和检查点。每完成一件事，就是攻下一个关卡、点亮一个赐福。

---

## Quick Start

直接在浏览器里打开 `index.html` 就行了。不需要 Node、不需要构建、不需要安装任何东西。

```
git clone https://github.com/<your-username>/life-open-world.git
cd life-open-world
# 双击 index.html
```

首次打开会有一组 Elden Ring 主题的示例数据，让你直观感受系统的运作方式。直接在上面改就行——数据保存在浏览器 localStorage 中。

---

## 数据架构

整个系统按 **六级层级** 递进，从大到小逐级精细：

```
标签 (Tag)
 └── 地标 (Landmark)
      └── 任务 (Quest)
           ├── 主线 / 支线 / 日常 / 挑战
           └── 关卡 (Level)
                └── 检查点 (Checkpoint)
                     └── 日历条目 (Calendar Entry)
```

| 层级 | 说明 | 例子 |
|---|---|---|
| **标签** | 地标的分类 | 城堡、森林、魔法学院 |
| **地标** | 一个生活/工作领域 | 个人成长、工作项目、健康 |
| **任务** | 领域下的具体目标 | 读完一本书、完成一个项目 |
| **关卡** | 任务的子阶段 | 收集资料 → 写大纲 → 写初稿 |
| **检查点** | 可追踪的最小执行单元 | 每天写 500 字 |
| **日历** | 检查点的每日执行记录 | 5月24日 ✓ 已完成 |

---

## 页面

| 页面 | 文件 | 干什么 |
|---|---|---|
| **世界地图** | `index.html` | 展示所有领地与地标的版图总览 |
| **命名管理** | `admin.html` | 创建和编辑标签、地标 |
| **任务管理** | `quest-admin.html` | 为地标添加任务（主线/支线/日常/挑战） |
| **关卡管理** | `level-admin.html` | 拆分任务为关卡和检查点 |
| **日历视图** | `calendar.html` | 日/周/月视图，安排和追踪检查点 |

所有页面共用顶部导航栏，可以随时切换。

---

## 功能亮点

- **🎮 游戏化设计** — 深色暗黑主题，Elden Ring 风格的金色/紫色/红色配色，Cinzel + Noto Serif SC 字体
- **📅 灵活日历** — 月视图、周视图、日视图，支持拖拽改期
- **📊 周总结** — 一键生成一周任务完成情况 Markdown 报告
- **📝 Obsidian 集成** — 通过 `obsidian://` URL Scheme 将周总结同步到 Obsidian vault
- **💾 离线优先** — 所有数据存储在浏览器 localStorage，无需联网
- **🛡️ XSS 防护** — 统一的 `LifeRPG.security` 安全层，输入过滤和 HTML 转义
- **📥 数据导出** — 支持导出 JSON、CSV、Excel 格式
- **🧩 零依赖** — 纯 HTML/CSS/JS，无框架，无构建工具

---

## 技术栈

```
HTML5 · CSS3 · Vanilla JavaScript · localStorage
Google Fonts (Cinzel, Crimson Text, Noto Serif SC)
SheetJS (Excel 导出，可选)
```

---

## 项目结构

```
├── index.html            # 世界地图
├── admin.html            # 命名管理
├── quest-admin.html      # 任务管理
├── level-admin.html      # 关卡管理
├── calendar.html         # 日历视图
├── common.css            # 公共样式
├── common.js             # 公共逻辑（安全、存储、数据管理）
└── tools/
    ├── export-data.html          # JSON 完整导出
    ├── export-data-simple.html   # JSON / CSV 导出
    ├── export-excel.html         # Excel 导出
    └── export-checkpoint-ids.html # 关卡数据导出
```

---

## 开发

`common.js` 向全局暴露了 `LifeRPG` 命名空间，所有数据操作都应通过它进行：

```javascript
// 加载数据
const data = LifeRPG.data.load();

// 安全保存
LifeRPG.data.save(data);

// 防抖
const debouncedFn = LifeRPG.dom.debounce(handler, 300);

// 安全 HTML 渲染
LifeRPG.security.escapeHtml(userInput);
```

## License

MIT
