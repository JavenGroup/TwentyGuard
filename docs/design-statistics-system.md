# 统计系统设计文档 - v1.1.0

> **文档类型**: 技术设计文档（已归档）
> **目标版本**: v1.1.0（已实施）
> **创建日期**: 2025-10-31
> **实施日期**: 2025-11-03
> **作者**: Javen Fang (@javenfang)
> **状态**: ✅ 已实施

---

**⚠️ 注意**: 本文档为历史归档，描述的设计已在 v1.1.0 中实施。

**当前实现文档**：
- [architecture.md](architecture.md) - 包含完整的技术架构和实现细节

---

## 1. 设计目标

### 1.1 核心问题

**当前系统的根本问题**:
1. **概念混淆**: Postpone 被记录为 Break Session,导致统计错误
2. **数据丢失**: Postpone 信息未正确关联到 Work Session
3. **统计不准**: Work Session 的 `postpone_count` 始终为 0

### 1.2 设计原则

1. **会话独立性**: Work/Postpone/Break 三种会话独立存储
2. **父子关联**: Postpone 和 Break 必须关联到对应的 Work Session
3. **生命周期完整**: 记录会话的完整状态转换(active → completed/interrupted)
4. **查询效率**: 统计查询应在 100ms 内完成

---

## 2. 数据库设计

### 2.1 设计原则

根据用户要求:
1. **历史数据完全丢弃** - 不做数据迁移
2. **使用 JSON 字段** - postpone/break 信息用 JSON 存储,避免多表
3. **主表统一** - 所有会话类型在一张表

### 2.2 新表结构设计

#### sessions 表(唯一的主表)

```sql
CREATE TABLE sessions (
    -- 基本信息
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    type TEXT CHECK(type IN ('work')) NOT NULL,  -- 只有 'work' 类型
    start_time REAL NOT NULL,
    end_time REAL,
    status TEXT CHECK(status IN ('active', 'completed', 'interrupted')) DEFAULT 'active',

    -- 工作时长
    planned_duration INTEGER DEFAULT 1800,        -- 计划工作时长(秒,默认 1800)
    actual_work_duration INTEGER,                 -- 实际工作时长(秒,含推迟)

    -- 推迟信息
    postpone_count INTEGER DEFAULT 0,             -- 推迟次数
    postpone_total_duration INTEGER DEFAULT 0,    -- 推迟总时长(秒)
    postpones TEXT,                               -- 推迟详情列表(JSON 数组)

    -- 休息信息
    break_info TEXT,                              -- 休息详情(JSON 对象)
    break_completed INTEGER DEFAULT 0,            -- 是否完成休息(0/1)

    -- 元数据
    created_at REAL DEFAULT (strftime('%s', 'now'))
);
```

**说明**:
- 只有 `work` 类型,每条记录代表一个完整的工作会话
- Break 信息存储在 `break_info` JSON 字段中
- 不再需要 `work_session_id` 外键(单条记录包含所有信息)

#### postpones JSON 字段格式(数组)

```json
[
    {
        "duration": 300,
        "start_time": 1698825600.5,
        "end_time": 1698825900.5,
        "status": "completed"
    },
    {
        "duration": 120,
        "start_time": 1698825900.5,
        "end_time": 1698826020.5,
        "status": "completed"
    },
    {
        "duration": 60,
        "start_time": 1698826020.5,
        "end_time": null,
        "status": "interrupted"
    }
]
```

**字段说明**:
- `duration`: 推迟时长(秒): 60/120/300
- `start_time`: 推迟开始时间(Unix timestamp)
- `end_time`: 推迟结束时间(null 表示未完成)
- `status`: `"completed"` | `"interrupted"`

#### break_info JSON 字段格式(对象)

```json
{
    "planned_duration": 180,
    "actual_duration": 180,
    "start_time": 1698827280.0,
    "end_time": 1698827460.0,
    "status": "completed"
}
```

**字段说明**:
- `planned_duration`: 计划休息时长(秒,通常 180)
- `actual_duration`: 实际休息时长(秒)
- `start_time`: 休息开始时间(Unix timestamp)
- `end_time`: 休息结束时间(null 表示未完成)
- `status`: `"completed"` | `"interrupted"` | `null`(未开始休息)

### 2.3 示例数据

#### 完整工作会话示例(含推迟和休息)
```json
{
    "id": 123,
    "type": "work",
    "start_time": 1698825000.0,
    "end_time": 1698827460.0,
    "status": "completed",
    "planned_duration": 1800,
    "actual_work_duration": 2280,
    "postpone_count": 3,
    "postpone_total_duration": 480,
    "postpones": [
        {"duration": 300, "start_time": 1698826800.0, "end_time": 1698827100.0, "status": "completed"},
        {"duration": 120, "start_time": 1698827100.0, "end_time": 1698827220.0, "status": "completed"},
        {"duration": 60, "start_time": 1698827220.0, "end_time": 1698827280.0, "status": "completed"}
    ],
    "break_info": {
        "planned_duration": 180,
        "actual_duration": 180,
        "start_time": 1698827280.0,
        "end_time": 1698827460.0,
        "status": "completed"
    },
    "break_completed": 1,
    "created_at": 1698825000.0
}
```

#### 用户主动休息示例(工作不足30分钟)
```json
{
    "id": 124,
    "type": "work",
    "start_time": 1698828000.0,
    "end_time": 1698828900.0,
    "status": "completed",
    "planned_duration": 1800,
    "actual_work_duration": 900,
    "postpone_count": 0,
    "postpone_total_duration": 0,
    "postpones": [],
    "break_info": {
        "planned_duration": 180,
        "actual_duration": 180,
        "start_time": 1698828900.0,
        "end_time": 1698829080.0,
        "status": "completed"
    },
    "break_completed": 1,
    "created_at": 1698828000.0
}
```

#### 系统唤醒中断示例(休息未完成)
```json
{
    "id": 125,
    "type": "work",
    "start_time": 1698830000.0,
    "end_time": 1698831800.0,
    "status": "interrupted",
    "planned_duration": 1800,
    "actual_work_duration": 1800,
    "postpone_count": 0,
    "postpone_total_duration": 0,
    "postpones": [],
    "break_info": {
        "planned_duration": 180,
        "actual_duration": 60,
        "start_time": 1698831800.0,
        "end_time": 1698831860.0,
        "status": "interrupted"
    },
    "break_completed": 0,
    "created_at": 1698830000.0
}
```

### 2.4 设计优势

**单表 + JSON 方案**:
- ✅ 每个工作会话只占 1 条记录
- ✅ 无需 JOIN 查询,性能更好
- ✅ JSON 字段灵活,易于扩展
- ✅ 推迟和休息详情完整保留
- ✅ 数据结构清晰,便于调试

**与旧方案对比**:
| 特性 | 旧方案(多表) | 新方案(单表+JSON) |
|------|-------------|------------------|
| 记录数 | 1 work + 1 break = 2条 | 1条 |
| 查询复杂度 | 需要 JOIN | 直接查询 |
| 推迟信息 | 丢失 | 完整保留 |
| 扩展性 | 需要加字段/表 | 修改 JSON 结构 |

---

## 3. 数据记录流程设计

### 3.1 Work Session 生命周期

```
开始工作
  ↓
  创建 sessions 记录 (status=active, postpones=[], break_info=null)
  ↓
  工作计时...
  ↓
  ┌─────────────────────────────────┐
  │  到达 30 分钟 OR 用户主动休息    │
  └─────────────────────────────┘
  ↓
  提示休息
  ↓
  用户选择:
  ├─ 推迟 → 添加到 postpones JSON 数组
  │         更新 postpone_count, postpone_total_duration
  │         继续工作...
  │         (可能多次推迟)
  │
  └─ 开始休息 → 创建 break_info JSON 对象
                休息倒计时...
                ├─ 完成 → 更新 break_info.status = "completed"
                │         更新 break_completed = 1, status = "completed"
                │
                └─ 系统唤醒中断 → 更新 break_info.status = "interrupted"
                                  更新 break_completed = 0, status = "interrupted"
```

### 3.2 关键操作说明

#### 记录推迟
1. 读取当前 `postpones` JSON 数组
2. 添加新的推迟记录对象
3. 更新 `postpone_count` 和 `postpone_total_duration`
4. 写回 JSON 数组

#### 开始休息
1. 创建 `break_info` JSON 对象
2. 设置 `planned_duration`, `start_time`, `status="active"`

#### 完成休息
1. 更新 `break_info.end_time`, `break_info.status="completed"`
2. 更新 `break_completed=1`, `status="completed"`

#### 系统唤醒中断
1. 检查当前活跃的 session
2. 如果在推迟中: 更新 `postpones` 数组最后一项的 `status="interrupted"`
3. 如果在休息中: 更新 `break_info.status="interrupted"`, `break_completed=0`
4. 更新 session `status="interrupted"`

---

## 4. 统计查询设计

### 4.1 今日用眼状况

```sql
-- 工作会话数
SELECT COUNT(*) FROM work_sessions
WHERE date(start_time, 'unixepoch', 'localtime') = date('now', 'localtime');

-- 最长工作时长
SELECT MAX(actual_work_duration) / 60 AS longest_work_minutes
FROM work_sessions
WHERE date(start_time, 'unixepoch', 'localtime') = date('now', 'localtime')
  AND actual_work_duration IS NOT NULL;

-- 完成休息次数
SELECT COUNT(*) FROM work_sessions
WHERE date(start_time, 'unixepoch', 'localtime') = date('now', 'localtime')
  AND break_completed = 1;

-- 推迟次数
SELECT SUM(postpone_count) FROM work_sessions
WHERE date(start_time, 'unixepoch', 'localtime') = date('now', 'localtime');

-- 推迟率
SELECT
    CAST(SUM(postpone_count) AS REAL) / COUNT(*) AS postpone_rate
FROM work_sessions
WHERE date(start_time, 'unixepoch', 'localtime') = date('now', 'localtime');
```

### 4.2 详细会话查询(用于调试)

```sql
-- 查询某个 Work Session 的完整信息
SELECT
    w.id,
    w.start_time,
    w.actual_work_duration,
    w.postpone_count,
    w.break_completed,
    -- Postpone Sessions
    (SELECT COUNT(*) FROM postpone_sessions WHERE work_session_id = w.id) AS postpone_sessions_count,
    (SELECT SUM(duration) FROM postpone_sessions WHERE work_session_id = w.id) AS total_postpone_duration,
    -- Break Session
    (SELECT status FROM break_sessions WHERE work_session_id = w.id LIMIT 1) AS break_status
FROM work_sessions w
WHERE w.id = ?;
```

### 4.3 性能优化

#### 索引设计
```sql
-- work_sessions 索引
CREATE INDEX idx_work_sessions_start_time
ON work_sessions(start_time);

CREATE INDEX idx_work_sessions_status
ON work_sessions(status);

-- postpone_sessions 索引
CREATE INDEX idx_postpone_sessions_work_id
ON postpone_sessions(work_session_id);

-- break_sessions 索引
CREATE INDEX idx_break_sessions_work_id
ON break_sessions(work_session_id);
```

---

## 5. JSONL 日志系统设计

### 5.1 设计定位

**JSONL 日志是重要的调试工具**,在架构中扮演关键角色:

1. **SQLite 数据库**: 持久化存储,用于统计查询(90天)
2. **JSONL 日志**: 完整事件流,用于调试和问题排查(30天)
3. **current_session.json**: 当前会话状态,用于系统唤醒恢复

### 5.2 JSONL 日志格式

#### 标准事件格式
```json
{
    "timestamp": "2025-11-02T14:30:00+0800",
    "eventType": "work_started",
    "sessionId": 123,
    "duration": 1800,
    "context": {
        "mode": "custom",
        "planned_duration": "1800"
    }
}
```

#### 完整的事件类型
```swift
enum EventType: String, Codable {
    // Work/Break 周期事件
    case workStarted = "work_started"
    case workCompleted = "work_completed"
    case workInterrupted = "work_interrupted"

    case breakStarted = "break_started"
    case breakCompleted = "break_completed"
    case breakInterrupted = "break_interrupted"

    case postponeStarted = "postpone_started"
    case postponeCompleted = "postpone_completed"
    case postponeInterrupted = "postpone_interrupted"

    // 系统事件
    case systemSleep = "system_sleep"
    case systemWake = "system_wake"
    case screenLock = "screen_lock"
    case screensaverStart = "screensaver_start"

    // 状态快照(每10秒)
    case stateSnapshot = "state_snapshot"

    // 数据库操作(可选)
    case dbInsert = "db_insert"
    case dbUpdate = "db_update"
}
```

### 5.3 关键事件示例

#### 工作会话开始
```json
{
    "timestamp": "2025-11-02T10:00:00+0800",
    "eventType": "work_started",
    "sessionId": 123,
    "context": {
        "planned_duration": 1800,
        "mode": "custom"
    }
}
```

#### 推迟记录
```json
{
    "timestamp": "2025-11-02T10:30:00+0800",
    "eventType": "postpone_started",
    "sessionId": 123,
    "duration": 300,
    "context": {
        "postpone_count": 1,
        "total_postponed": 300,
        "remaining_postpone_budget": 300
    }
}
```

#### 数据库操作记录
```json
{
    "timestamp": "2025-11-02T10:30:00+0800",
    "eventType": "db_update",
    "context": {
        "table": "sessions",
        "id": 123,
        "operation": "add_postpone",
        "postpone_count": 1,
        "postpone_total_duration": 300,
        "postpones_json": "[{\"duration\":300,\"start_time\":1698826800.0,\"status\":\"active\"}]"
    }
}
```

#### 系统唤醒中断
```json
{
    "timestamp": "2025-11-02T14:00:00+0800",
    "eventType": "system_wake",
    "context": {
        "interrupted_sessions": [
            {"id": 123, "type": "work", "status": "interrupted"},
            {"id": 125, "type": "postpone", "status": "interrupted"}
        ],
        "action": "reset_to_new_work_session"
    }
}
```

### 5.4 日志与数据库的关系

```
用户操作 → 写入 SQLite → 同时写入 JSONL 日志
           (持久化)      (调试记录)
```

**关键原则**:
1. **双写**: 每个数据库操作都记录到 JSONL
2. **包含 sessionId**: JSONL 事件关联数据库记录
3. **完整上下文**: JSONL 记录足够信息用于重现问题

### 5.5 调试场景示例

#### 场景: 推迟次数为 0 的问题

**步骤 1**: 查询数据库
```sql
SELECT * FROM sessions WHERE type='work' AND postpone_count=0 AND date(start_time, 'unixepoch')='2025-11-01';
-- 发现 session_id = 123 的推迟次数为 0,但用户确实推迟了
```

**步骤 2**: 查看 JSONL 日志
```bash
grep "session.*123" ~/Library/Application\ Support/com.twentytwentytwenty/logs/2025-11-01.jsonl
```

**步骤 3**: 分析日志输出
```json
{"timestamp":"2025-11-01T10:00:00+0800","eventType":"work_started","sessionId":123}
{"timestamp":"2025-11-01T10:30:00+0800","eventType":"postpone_started","sessionId":123,"duration":300}
{"timestamp":"2025-11-01T10:30:00+0800","eventType":"db_update","context":{"error":"no active work session found"}}
```

**结论**: 发现 `db_update` 失败,`recordPostpone()` 找不到活跃的 work session

### 5.6 日志管理

#### 文件命名
```
~/Library/Application Support/com.twentytwentytwenty/logs/
├── 2025-11-01.jsonl
├── 2025-11-02.jsonl
└── 2025-11-03.jsonl
```

#### 自动清理
- 保留最近 30 天的日志
- 每天午夜自动清理过期日志
- 日志文件大小通常 1-2MB/天

#### 查询工具
```bash
# 查看今天的所有推迟事件
grep "postpone" ~/Library/.../logs/$(date +%Y-%m-%d).jsonl | jq .

# 统计今天的事件类型分布
grep -o '"eventType":"[^"]*"' ~/Library/.../logs/$(date +%Y-%m-%d).jsonl | sort | uniq -c

# 查找特定 session 的完整生命周期
grep "sessionId.*123" ~/Library/.../logs/2025-11-01.jsonl | jq .
```

---

## 6. 数据迁移方案

### 6.1 迁移策略

根据用户要求: **历史数据完全丢弃**

### 6.2 迁移步骤

#### Step 1: 检测旧版本数据库
- 检查 sessions 表是否有 `postpones` 和 `break_info` 字段
- 如果没有,说明是旧版本

#### Step 2: 执行迁移
1. 重命名旧表: `sessions → sessions_v1_backup`
2. 删除 daily_summary 数据
3. 创建新表结构
4. 记录迁移日志到 JSONL

#### Step 3: 用户提示
- 首次运行显示提示:"检测到数据库升级,历史统计数据已重置。从 v1.2.0 开始,统计数据将更加准确。"

### 6.3 回滚方案

不支持回滚(历史数据已丢弃)

---

## 7. 代码改动范围

### 7.1 StatsDatabase.swift
- 修改表结构:添加 `postpones TEXT`, `break_info TEXT` 字段
- JSON 序列化/反序列化方法
- 记录推迟:读取、修改、写回 JSON
- 记录休息:创建、更新 `break_info` JSON 对象
- 系统事件中断:更新 JSON 状态字段

### 7.2 AppDelegate.swift
- 状态变量:保存当前 work session ID
- 推迟操作:调用数据库更新 JSON
- 休息操作:调用数据库创建/更新 JSON
- 系统唤醒:调用数据库标记中断状态

### 7.3 LogManager.swift
- 新增事件类型:
  - `postponeStarted`, `postponeCompleted`, `postponeInterrupted`
  - `dbInsert`, `dbUpdate`, `dbMigration`
- 所有数据库操作都写入 JSONL 日志

---

## 8. 测试计划

### 8.1 数据库 JSON 测试
- JSON 序列化/反序列化正确性
- 多次推迟正确添加到数组
- Break info JSON 创建和更新
- 系统中断时 JSON 状态更新

### 8.2 集成测试场景

#### 场景 1: 完整工作-推迟-休息周期
```
1. 启动应用 → 工作 30 分钟 → 推迟 5 分钟 → 推迟 2 分钟 → 完成休息

   验证数据库:
   - Work Session: postpone_count=2, postpone_total_duration=420, break_completed=1
   - postpones JSON: [{"duration":300,...}, {"duration":120,...}]
   - Break Session: status=completed, work_session_id=<work_id>

   验证 JSONL:
   - work_started
   - postpone_started (2次)
   - postpone_completed (2次)
   - break_started
   - break_completed
```

#### 场景 2: 系统唤醒中断推迟
```
2. 工作 30 分钟 → 推迟 5 分钟 → 2分钟后合盖 → 1小时后打开

   验证数据库:
   - Work Session: status=interrupted, postpone_count=1
   - postpones JSON: [{"duration":300, "status":"interrupted"}]

   验证 JSONL:
   - work_started
   - postpone_started
   - system_sleep
   - system_wake
   - postpone_interrupted
   - work_interrupted
```

### 8.3 JSONL 日志验证
- 验证每个数据库操作都有对应的 JSONL 记录
- 验证 JSONL 事件数量与数据库记录一致
- 验证 sessionId 正确关联

---

## 9. 风险与缓解

### 9.1 JSON 字段风险

**风险**: SQLite 旧版本不支持 JSON 函数
**缓解**:
- macOS 12.0+ 自带 SQLite 3.37+(支持 JSON)
- 应用要求 macOS 12.0+,无兼容性问题
- JSON 作为 TEXT 存储,即使不用 JSON 函数也能读取

### 9.2 数据一致性风险

**风险**: postpones JSON 与 postpone_count 不一致
**缓解**:
- 每次更新 JSON 时同步更新 count 字段
- 添加数据库约束检查
- JSONL 日志记录所有操作,便于事后审计

### 9.3 迁移风险

**风险**: 用户升级后数据丢失不满意
**缓解**:
- 发布说明明确提示"统计数据将重置"
- 保留旧表备份(sessions_v1_backup)
- 提供"导出历史数据"功能(可选)

---

## 10. 时间估算

| 任务 | 工作量 | 依赖 |
|------|-------|------|
| StatsDatabase.swift - JSON 方法 | 2h | - |
| StatsDatabase.swift - 表结构迁移 | 1h | JSON 方法 |
| StatsDatabase.swift - 记录方法改造 | 3h | 表结构 |
| AppDelegate.swift - 状态管理调整 | 2h | StatsDatabase |
| LogManager.swift - 事件类型补充 | 0.5h | - |
| 单元测试 - JSON 序列化 | 1h | JSON 方法 |
| 集成测试 - 完整场景 | 2h | 代码改造 |
| JSONL 日志验证 | 1h | 集成测试 |
| 文档更新(架构文档) | 0.5h | - |
| **总计** | **13h** | |

---

## 11. 架构决策记录(ADR)

### ADR-001: 使用 JSON 字段而非多表设计

**背景**: 需要记录每个工作会话的多次推迟详情

**决策**: 采用单表 + JSON 字段方案,而非创建独立的 `postpone_sessions` 表

**理由**:
1. **简化查询**: 无需 JOIN,直接读取 work session 即可获取所有推迟信息
2. **灵活性**: JSON 字段易于扩展,未来可添加更多推迟属性(如推迟原因)
3. **用户要求**: 明确要求"多用 JSON 字段"
4. **技术可行**: macOS 12.0+ SQLite 原生支持 JSON 操作

**取舍**:
- ✅ 优势: 结构简单、查询快速、扩展性好
- ❌ 劣势: JSON 查询语法稍复杂(但我们不需要在 JSON 内部搜索)

### ADR-002: JSONL 日志作为核心调试工具

**背景**: 需要排查统计数据不准确的问题

**决策**: 将 JSONL 日志提升为架构的重要组成部分,而非可选的调试工具

**理由**:
1. **用户要求**: "需要在架构设计中体现"
2. **调试价值**: 可重现完整事件流,快速定位数据不一致问题
3. **审计追踪**: 记录所有数据库操作,便于事后分析
4. **低成本**: 文件追加写入,性能影响小

**实现**:
- 每个数据库操作都写入对应的 JSONL 事件
- 包含 sessionId 关联数据库记录
- 提供查询工具和示例

### ADR-003: 历史数据完全丢弃

**背景**: 旧版本统计数据不准确,需要数据迁移

**决策**: 不尝试修复或迁移历史数据,从 v1.2.0 开始重新统计

**理由**:
1. **用户要求**: "历史数据,完全扔掉"
2. **数据质量**: 旧数据无法准确判断哪些是推迟,修复成本高
3. **简化实现**: 无需复杂的数据转换逻辑
4. **全新开始**: 新架构从一开始就保证数据准确

**用户沟通**:
- 升级提示明确说明统计数据将重置
- 可选:提供旧数据导出功能(只读)

---

## 12. 相关文档

- **[PRD: 统计需求变更](prd-statistics-requirements.md)** - 需求定义
- **[架构文档](architecture.md)** - 系统架构(需要更新)
- **[Bug 修复历史](bugfix-history.md)** - BUG-004 推迟统计问题

---

## 13. 附录

### 13.1 数据文件位置

```
~/Library/Application Support/com.twentytwentytwenty/
├── 20_20_20_stats.db          # 主数据库(v1.2.0 新结构)
├── sessions_v1_backup         # 旧表备份(可选删除)
├── current_session.json       # 当前会话状态
└── logs/
    ├── 2025-11-01.jsonl      # 每日 JSONL 日志
    ├── 2025-11-02.jsonl
    └── ...
```

### 13.2 SQL 查询示例

#### 查询工作会话及其推迟详情
```sql
SELECT
    id,
    datetime(start_time, 'unixepoch', 'localtime') AS start_time,
    postpone_count,
    postpone_total_duration / 60 AS postpone_minutes,
    postpones
FROM sessions
WHERE type = 'work'
  AND date(start_time, 'unixepoch', 'localtime') = date('now', 'localtime')
ORDER BY start_time DESC;
```

#### 使用 JSON 函数统计(可选)
```sql
-- 统计所有推迟状态分布
SELECT
    json_extract(value, '$.status') AS postpone_status,
    COUNT(*) AS count
FROM sessions,
     json_each(sessions.postpones)
WHERE type = 'work'
GROUP BY postpone_status;
```

---

**状态**: 📝 待用户确认后进入实现阶段
