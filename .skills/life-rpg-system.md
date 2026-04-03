# LIFE RPG 人生开放系统

## 项目概述

一个受艾尔登法环启发的游戏化人生任务管理系统，采用层级结构设计：

```
标签 (tags) → 地标 (landmarks) → 任务 (quests) → 关卡 (levels) → 检查点 (checkpoints) → 日历条目 (calendar entries)
```

## 项目文件结构

```
G:\人生开放系统\
├── index.html          # 世界地图 - 展示领地与地标
├── admin.html          # 命名管理 - 管理标签和地标
├── quest-admin.html    # 任务管理 - 管理地标下的任务
├── level-admin.html    # 关卡管理 - 管理任务下的关卡和检查点
├── calendar.html       # 日历视图 - 日历调度和检查点追踪
├── common.css          # 公共样式
├── common.js           # 公共模块（安全、存储、数据管理）
└── .git/               # Git版本控制
```

## 数据存储结构

存储键: `lifeRpgAdminData`

```javascript
{
    // 1. 标签系统 - 地标分类
    tags: [
        { id: 1, name: '城堡', icon: '🏰', desc: '描述' }
    ],

    // 2. 地标 - 主要地点
    landmarks: [
        { id: 1, name: '史东薇尔城', icon: '🏰', type: '城堡', desc: '...', boss: '接肢贵族' }
    ],

    // 3. 地标任务 - 按地标ID分组
    landmarkQuests: {
        "1": [
            { id: 101, name: '探索城堡外围', type: 'main', rewardType: 'exp', rewardAmount: 100 }
        ]
    },

    // 4. 任务关卡 - 按任务ID分组
    questLevels: {
        "101": [
            { id: 1001, name: '关卡1', time: 5, checkpoints: [
                { id: 'cp1', name: '检查点1', time: 2 }
            ]}
        ]
    },

    // 5. 日历条目 - 按日期分组
    calendarEntries: {
        "2025-01-15": [
            { id: '...', checkpointId: '...', checkpointName: '...', description: '', completed: true/false }
        ]
    },

    // 6. 检查点完成历史 - 跨天追踪
    checkpointCompletions: {
        "checkpointId_123": [
            { date: '2025-01-15', entryId: '...', archived: true/false }
        ]
    }
}
```

## 核心功能模块

### 1. 安全模块 (LifeRPG.security)
- `escapeHtml(text)` - HTML转义防止XSS
- `isSafeInput(input, maxLength)` - 输入验证
- `sanitizeObject(obj)` - 对象净化

### 2. 存储模块 (LifeRPG.storage)
- `save(key, data)` - 安全保存到localStorage
- `load(key, defaultValue)` - 安全加载
- `remove(key)` - 删除数据
- `getUsage()` - 获取存储使用量

### 3. 数据管理 (LifeRPG.data)
- `load()` - 加载游戏数据
- `save(data)` - 保存游戏数据
- `reset()` - 重置为默认数据

### 4. DOM工具 (LifeRPG.dom)
- `debounce(func, wait)` - 防抖
- `throttle(func, limit)` - 节流
- `safeSetHTML(element, html)` - 安全设置HTML

### 5. 事件管理 (LifeRPG.events)
- `add(element, event, handler, options)` - 添加监听
- `removeAll(element)` - 移除元素所有监听
- `clear()` - 清理所有监听

### 6. 常量定义 (LifeRPG.constants)
- `QUEST_TYPES` - 任务类型配置
- `REWARD_TYPES` - 奖励类型配置
- `ICONS` - 可用图标列表
- `MONTH_NAMES` - 月份名称
- `WEEKDAYS` - 星期名称
- `CALENDAR_GRID_DAYS` - 日历网格天数(42)

## 页面导航

| 页面 | 功能 | 导航active |
|------|------|-----------|
| index.html | 世界地图展示 | 世界地图 |
| admin.html | 标签和地标管理 | 命名管理 |
| quest-admin.html | 任务管理 | 任务管理 |
| level-admin.html | 关卡和检查点管理 | 关卡管理 |
| calendar.html | 日历调度和追踪 | 日历视图 |

## 设计规范

### 颜色系统
- 背景: `#0a0a0c` (深黑)
- 面板: `#121216`
- 强调金: `#c9a227`
- 强调紫: `#7b68ee`
- 强调红: `#d4634e`

### 字体
- 标题: `'Cinzel', 'Noto Serif SC', serif`
- 正文: `'Crimson Text', 'Noto Serif SC', serif`

### 尺寸
- 顶部导航高度: 80px
- 最大内容宽度: 1400px
- 面板间距: 30px

## 开发注意事项

1. **必须使用公共模块**: 所有数据操作通过 `LifeRPG` 命名空间
2. **XSS防护**: 所有用户输入必须使用 `LifeRPG.security.escapeHtml()` 转义
3. **错误处理**: 所有可能出错的操作使用 try-catch
4. **事件管理**: 使用 `LifeRPG.events.add()` 防止内存泄漏
5. **代码复用**: 公共样式在 common.css，公共逻辑在 common.js

## 版本历史

- v1.0.0 - 初始版本，五个页面功能完整
- v1.1.0 - 代码重构，提取公共模块，修复XSS漏洞

## 技术栈

- 纯 HTML/CSS/JavaScript
- 无框架依赖
- localStorage 数据持久化
- Git 版本控制
