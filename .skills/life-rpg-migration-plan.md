# LIFE RPG 数据迁移方案

> 状态：待执行  
> 适用时机：数据结构稳定后 / localStorage 接近 5MB 容量限制  
> 创建日期：2025-04-03

---

## 一、迁移前准备

### 1.1 确认迁移条件

在执行迁移前，请确认以下条件已满足：

- [ ] 产品功能已基本完成，不再大幅调整
- [ ] 数据结构已稳定，字段不再频繁变更
- [ ] 当前数据量接近 4MB（localStorage 容量约 5MB）
- [ ] 有充足时间进行测试和验证

### 1.2 当前架构回顾

```
当前：浏览器 localStorage
  └── 存储键：'lifeRpgAdminData'
  └── 格式：JSON 字符串
  └── 容量：约 5MB
  └── 位置：浏览器内部，不在项目文件夹
```

### 1.3 目标架构

```
目标：Node.js + SQLite
  └── server.js          # Express API 服务器
  └── database.sqlite    # SQLite 数据库文件
  └── public/            # 前端静态文件
  └── 数据位置：本地文件，Git 可追踪
```

---

## 二、迁移步骤详解

### Step 1: 数据导出备份（零风险）

**目标：** 将现有 localStorage 数据导出为 JSON 文件

**操作：**

1. 在浏览器控制台执行导出脚本：

```javascript
// 导出脚本 - 在浏览器控制台运行
const data = localStorage.getItem('lifeRpgAdminData');
const blob = new Blob([data], { type: 'application/json' });
const url = URL.createObjectURL(blob);
const a = document.createElement('a');
a.href = url;
a.download = `data_backup_${new Date().toISOString().split('T')[0]}.json`;
a.click();
URL.revokeObjectURL(url);
console.log('数据已导出');
```

2. 保存生成的 JSON 文件到项目目录：
   ```
   G:\人生开放系统\
   ├── migration_backup\
   │   └── data_backup_2025-04-03.json
   ```

**检查点：**
- [ ] JSON 文件已生成
- [ ] 文件大小 > 0
- [ ] 能用文本编辑器打开查看内容

---

### Step 2: 创建后端项目结构

**目标：** 搭建 Node.js + Express + SQLite 后端

**操作：**

1. 在项目根目录初始化 Node.js 项目：

```bash
cd "G:\人生开放系统"
npm init -y
```

2. 安装依赖：

```bash
npm install express sqlite3 cors body-parser
npm install --save-dev nodemon
```

3. 创建项目结构：

```
G:\人生开放系统\
├── server.js              # 主服务器文件
├── database.sqlite        # SQLite 数据库（自动创建）
├── package.json           # 项目配置
├── .gitignore             # Git 忽略配置
├── public/                # 前端文件（从根目录移入）
│   ├── index.html
│   ├── admin.html
│   ├── quest-admin.html
│   ├── level-admin.html
│   ├── calendar.html
│   ├── common.css
│   └── common.js
└── migration_backup/      # 迁移备份
    └── data_backup_*.json
```

4. 创建 `.gitignore`：

```gitignore
node_modules/
*.log
.DS_Store
```

---

### Step 3: 创建数据库和 API

**目标：** 创建 SQLite 数据库结构和 REST API

**文件：server.js**

```javascript
const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const cors = require('cors');
const path = require('path');

const app = express();
const PORT = 3000;

// 中间件
app.use(cors());
app.use(express.json());
app.use(express.static('public'));

// 数据库连接
const db = new sqlite3.Database('database.sqlite', (err) => {
    if (err) {
        console.error('数据库连接失败:', err);
    } else {
        console.log('已连接到 SQLite 数据库');
        initDatabase();
    }
});

// 初始化数据库表
function initDatabase() {
    db.serialize(() => {
        // 标签表
        db.run(`CREATE TABLE IF NOT EXISTS tags (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE NOT NULL,
            icon TEXT,
            desc TEXT
        )`);

        // 地标表
        db.run(`CREATE TABLE IF NOT EXISTS landmarks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE NOT NULL,
            icon TEXT,
            type TEXT,
            desc TEXT,
            boss TEXT
        )`);

        // 任务表
        db.run(`CREATE TABLE IF NOT EXISTS quests (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            landmark_id INTEGER,
            name TEXT NOT NULL,
            type TEXT,
            reward_type TEXT,
            reward_amount INTEGER,
            desc TEXT,
            FOREIGN KEY (landmark_id) REFERENCES landmarks(id)
        )`);

        // 关卡表
        db.run(`CREATE TABLE IF NOT EXISTS levels (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            quest_id INTEGER,
            name TEXT NOT NULL,
            time INTEGER,
            checkpoints TEXT,  -- JSON 字符串
            FOREIGN KEY (quest_id) REFERENCES quests(id)
        )`);

        // 日历条目表
        db.run(`CREATE TABLE IF NOT EXISTS calendar_entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            checkpoint_id TEXT,
            checkpoint_name TEXT,
            level_id INTEGER,
            quest_id INTEGER,
            landmark_name TEXT,
            description TEXT,
            completed BOOLEAN DEFAULT 0,
            archived BOOLEAN DEFAULT 0
        )`);

        // 检查点完成历史表
        db.run(`CREATE TABLE IF NOT EXISTS checkpoint_completions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            checkpoint_id TEXT NOT NULL,
            date TEXT NOT NULL,
            entry_id INTEGER,
            archived BOOLEAN DEFAULT 0
        )`);
    });
}

// ==================== API 路由 ====================

// 获取所有数据（用于前端初始化）
app.get('/api/data', (req, res) => {
    const result = {
        tags: [],
        landmarks: [],
        landmarkQuests: {},
        questLevels: {},
        calendarEntries: {},
        checkpointCompletions: {}
    };

    // 查询标签
    db.all('SELECT * FROM tags', [], (err, rows) => {
        if (err) return res.status(500).json({ error: err.message });
        result.tags = rows;

        // 查询地标
        db.all('SELECT * FROM landmarks', [], (err, rows) => {
            if (err) return res.status(500).json({ error: err.message });
            result.landmarks = rows;

            // 查询任务并按地标分组
            db.all('SELECT * FROM quests', [], (err, rows) => {
                if (err) return res.status(500).json({ error: err.message });
                rows.forEach(quest => {
                    if (!result.landmarkQuests[quest.landmark_id]) {
                        result.landmarkQuests[quest.landmark_id] = [];
                    }
                    result.landmarkQuests[quest.landmark_id].push(quest);
                });

                // 查询关卡并按任务分组
                db.all('SELECT * FROM levels', [], (err, rows) => {
                    if (err) return res.status(500).json({ error: err.message });
                    rows.forEach(level => {
                        result.questLevels[level.quest_id] = {
                            ...level,
                            checkpoints: JSON.parse(level.checkpoints || '[]')
                        };
                    });

                    // 查询日历条目
                    db.all('SELECT * FROM calendar_entries', [], (err, rows) => {
                        if (err) return res.status(500).json({ error: err.message });
                        rows.forEach(entry => {
                            if (!result.calendarEntries[entry.date]) {
                                result.calendarEntries[entry.date] = [];
                            }
                            result.calendarEntries[entry.date].push(entry);
                        });

                        // 查询检查点完成历史
                        db.all('SELECT * FROM checkpoint_completions', [], (err, rows) => {
                            if (err) return res.status(500).json({ error: err.message });
                            rows.forEach(h => {
                                if (!result.checkpointCompletions[h.checkpoint_id]) {
                                    result.checkpointCompletions[h.checkpoint_id] = [];
                                }
                                result.checkpointCompletions[h.checkpoint_id].push(h);
                            });

                            res.json(result);
                        });
                    });
                });
            });
        });
    });
});

// 保存所有数据
app.post('/api/data', (req, res) => {
    const data = req.body;
    
    // 这里使用事务批量插入/更新
    // 为简化示例，此处省略具体实现
    
    res.json({ success: true, message: '数据已保存' });
});

// 单个资源的 CRUD API（可选，用于增量更新）
// ...

// 启动服务器
app.listen(PORT, () => {
    console.log(`服务器运行在 http://localhost:${PORT}`);
});

// 优雅关闭
process.on('SIGINT', () => {
    db.close((err) => {
        if (err) console.error(err.message);
        console.log('数据库连接已关闭');
        process.exit(0);
    });
});
```

---

### Step 4: 数据迁移脚本

**目标：** 将 JSON 备份导入 SQLite

**文件：migrate.js**

```javascript
const sqlite3 = require('sqlite3').verbose();
const fs = require('fs');
const path = require('path');

const db = new sqlite3.Database('database.sqlite');

// 读取备份文件
const backupFile = process.argv[2] || 'migration_backup/data_backup_2025-04-03.json';
const rawData = fs.readFileSync(path.join(__dirname, backupFile), 'utf8');
const data = JSON.parse(rawData);

console.log('开始迁移数据...');

db.serialize(() => {
    // 开启事务
    db.run('BEGIN TRANSACTION');

    // 1. 迁移标签
    const tagStmt = db.prepare('INSERT OR REPLACE INTO tags (id, name, icon, desc) VALUES (?, ?, ?, ?)');
    data.tags.forEach(tag => {
        tagStmt.run(tag.id, tag.name, tag.icon, tag.desc);
    });
    tagStmt.finalize();
    console.log(`✓ 标签: ${data.tags.length} 条`);

    // 2. 迁移地标
    const lmStmt = db.prepare('INSERT OR REPLACE INTO landmarks (id, name, icon, type, desc, boss) VALUES (?, ?, ?, ?, ?, ?)');
    data.landmarks.forEach(lm => {
        lmStmt.run(lm.id, lm.name, lm.icon, lm.type, lm.desc, lm.boss);
    });
    lmStmt.finalize();
    console.log(`✓ 地标: ${data.landmarks.length} 条`);

    // 3. 迁移任务
    let questCount = 0;
    const questStmt = db.prepare('INSERT OR REPLACE INTO quests (id, landmark_id, name, type, reward_type, reward_amount, desc) VALUES (?, ?, ?, ?, ?, ?, ?)');
    for (const [landmarkId, quests] of Object.entries(data.landmarkQuests || {})) {
        quests.forEach(quest => {
            questStmt.run(quest.id, landmarkId, quest.name, quest.type, quest.rewardType, quest.rewardAmount, quest.desc);
            questCount++;
        });
    }
    questStmt.finalize();
    console.log(`✓ 任务: ${questCount} 条`);

    // 4. 迁移关卡
    let levelCount = 0;
    const levelStmt = db.prepare('INSERT OR REPLACE INTO levels (id, quest_id, name, time, checkpoints) VALUES (?, ?, ?, ?, ?)');
    for (const [questId, level] of Object.entries(data.questLevels || {})) {
        levelStmt.run(level.id, questId, level.name, level.time, JSON.stringify(level.checkpoints || []));
        levelCount++;
    }
    levelStmt.finalize();
    console.log(`✓ 关卡: ${levelCount} 条`);

    // 5. 迁移日历条目
    let entryCount = 0;
    const entryStmt = db.prepare('INSERT OR REPLACE INTO calendar_entries (id, date, checkpoint_id, checkpoint_name, level_id, quest_id, landmark_name, description, completed, archived) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');
    for (const [date, entries] of Object.entries(data.calendarEntries || {})) {
        entries.forEach(entry => {
            entryStmt.run(entry.id, date, entry.checkpointId, entry.checkpointName, entry.levelId, entry.questId, entry.landmarkName, entry.description, entry.completed ? 1 : 0, entry.archived ? 1 : 0);
            entryCount++;
        });
    }
    entryStmt.finalize();
    console.log(`✓ 日历条目: ${entryCount} 条`);

    // 6. 迁移检查点完成历史
    let historyCount = 0;
    const historyStmt = db.prepare('INSERT OR REPLACE INTO checkpoint_completions (checkpoint_id, date, entry_id, archived) VALUES (?, ?, ?, ?)');
    for (const [checkpointId, histories] of Object.entries(data.checkpointCompletions || {})) {
        histories.forEach(h => {
            historyStmt.run(checkpointId, h.date, h.entryId, h.archived ? 1 : 0);
            historyCount++;
        });
    }
    historyStmt.finalize();
    console.log(`✓ 完成历史: ${historyCount} 条`);

    // 提交事务
    db.run('COMMIT', (err) => {
        if (err) {
            console.error('迁移失败:', err);
            db.run('ROLLBACK');
        } else {
            console.log('\n✅ 数据迁移完成！');
            console.log('数据库文件: database.sqlite');
        }
        db.close();
    });
});
```

**执行迁移：**

```bash
node migrate.js migration_backup/data_backup_2025-04-03.json
```

---

### Step 5: 修改前端代码

**目标：** 将数据读取从 localStorage 改为 API 调用

**修改 common.js：**

```javascript
// 修改前：
// const saved = StorageManager.load('lifeRpgAdminData');

// 修改后：
const API_BASE = 'http://localhost:3000/api';

const GameDataManager = {
    // 异步加载数据
    async load() {
        try {
            const response = await fetch(`${API_BASE}/data`);
            if (!response.ok) throw new Error('API 请求失败');
            const data = await response.json();
            return { ...this.defaultData, ...data };
        } catch (error) {
            console.error('加载数据失败:', error);
            // 失败时返回默认数据
            return { ...this.defaultData };
        }
    },

    // 异步保存数据
    async save(data) {
        try {
            const response = await fetch(`${API_BASE}/data`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(data)
            });
            if (!response.ok) throw new Error('API 请求失败');
            return true;
        } catch (error) {
            console.error('保存数据失败:', error);
            return false;
        }
    }
};
```

**修改页面初始化代码：**

```javascript
// 修改前：
// function init() {
//     const data = LifeRPG.data.load();
//     render(data);
// }

// 修改后：
async function init() {
    const data = await LifeRPG.data.load();
    render(data);
}
```

---

### Step 6: 验证和测试

**验证清单：**

- [ ] 启动服务器：`node server.js`
- [ ] 访问 http://localhost:3000 能正常打开页面
- [ ] 数据条数与备份一致
- [ ] 抽查数据内容正确
- [ ] 新增数据能正常保存
- [ ] 刷新页面数据不丢失
- [ ] 关闭服务器后重新启动，数据仍在

**数据对比脚本：**

```javascript
// verify.js - 验证数据完整性
const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('database.sqlite');

console.log('数据验证报告：\n');

db.get('SELECT COUNT(*) as count FROM tags', [], (err, row) => {
    console.log(`标签数量: ${row.count}`);
});

db.get('SELECT COUNT(*) as count FROM landmarks', [], (err, row) => {
    console.log(`地标数量: ${row.count}`);
});

db.get('SELECT COUNT(*) as count FROM quests', [], (err, row) => {
    console.log(`任务数量: ${row.count}`);
});

db.get('SELECT COUNT(*) as count FROM calendar_entries', [], (err, row) => {
    console.log(`日历条目: ${row.count}`);
});

db.close();
```

---

## 三、回滚方案

如果迁移后发现问题，可以立即回滚：

### 3.1 数据回滚

1. 停止 Node.js 服务器
2. 删除 `database.sqlite`
3. 从备份 JSON 恢复 localStorage：

```javascript
// 在浏览器控制台执行
const backup = `粘贴备份JSON内容`;
localStorage.setItem('lifeRpgAdminData', backup);
location.reload();
```

### 3.2 代码回滚

1. 恢复原来的 HTML 文件（从 Git 历史）
2. 移除 server.js 和相关依赖
3. 恢复使用 localStorage 的版本

---

## 四、后续优化（可选）

### 4.1 Excel 导出功能

```javascript
// export-excel.js
const xlsx = require('xlsx');
const sqlite3 = require('sqlite3').verbose();

// 查询数据并导出为 Excel
// ...
```

### 4.2 数据压缩

如果数据量很大，可以在传输时压缩：

```javascript
// 使用 pako 库压缩
const pako = require('pako');
const compressed = pako.deflate(JSON.stringify(data));
```

### 4.3 自动备份

设置定时任务自动备份数据库：

```bash
# Windows 定时任务
schtasks /create /tn "LIFE_RPG_Backup" /tr "copy database.sqlite backup\database_%date:~0,4%%date:~5,2%%date:~8,2%.sqlite" /sc daily /st 02:00
```

---

## 五、命令速查

```bash
# 1. 安装依赖
npm install

# 2. 启动开发服务器
npm run dev
# 或
node server.js

# 3. 数据迁移
node migrate.js migration_backup/data_backup_*.json

# 4. 验证数据
node verify.js

# 5. 导出 Excel
node export-excel.js
```

---

## 六、注意事项

1. **不要在迁移过程中使用系统**，避免数据不一致
2. **保留备份文件至少一个月**，确认稳定后再删除
3. **定期备份 database.sqlite 文件**，防止意外损坏
4. **SQLite 文件可以用 Git 追踪**，但注意文件大小
5. **如果数据量超过 100MB**，考虑使用 PostgreSQL 替代 SQLite

---

## 七、联系人

- 创建者：Qoder
- 创建日期：2025-04-03
- 最后更新：2025-04-03
