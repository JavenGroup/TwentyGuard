# 20-20-20 Bug 修复历史

> **文档版本**: v1.1.0
> **文档目的**: 详细记录所有重要 Bug 的发现、分析、修复过程，避免同一问题反复出现
> **维护者**: Javen Fang (@javenfang)
> **最后更新**: 2025-10-31

---

## 📋 目录

- [活跃 Bug](#活跃-bug)
- [已修复 Bug](#已修复-bug)
- [修复模式总结](#修复模式总结)

---

## 活跃 Bug

**当前无活跃 Bug** ✅

---

## 已修复 Bug

### ✅ BUG-001: 合盖/唤醒后继承旧会话导致立即提示休息

**严重程度**: 🔴 高 - 严重影响用户体验

**首次报告**: 2025-10-31
**复现次数**: 多次（该问题曾修复过多次，但反复出现）
**修复日期**: 2025-10-31
**修复版本**: v1.1.0
**状态**: ✅ 已修复并测试通过

#### 问题描述

**用户场景**:
```
1. 用户在家里使用电脑，工作 30 分钟
2. 应用提示休息，用户多次推迟（总共推迟约 10 分钟）
3. 用户合上笔记本盖子，离开家去办公室（路上 20-30 分钟）
4. 到达办公室，打开电脑
5. 打开后不久，应用又提示休息
```

**用户期望**:
- **核心需求**：无论之前什么状态，打开电脑后应该直接进入「工作状态」
- 开始一个全新的 30 分钟工作周期
- 不继承之前的会话或推迟状态

**实际行为**:
- 合盖期间，应用继续在后台计时（如果没有触发睡眠事件）
- 打开电脑时，旧的休息会话刚好结束，立即开始新工作会话
- 或者旧的工作会话还在进行，几分钟后就提示休息

#### 根因分析 ✅ 已确认

**通过数据库历史记录分析（2025-10-31 10:45）**:

**真实时间线**（本地时间）:
```
09:45:31 - 10:15:32  在家工作 30 分钟（会话 2735）
10:15:32            应用提示休息
10:15:32 - 10:25:39  用户推迟休息 5 次（共 10 分钟）
                    期间用户合上笔记本，前往办公室（约 20-30 分钟路程）
10:25:39            推迟的休息时间结束，应用开始新工作会话（会话 2741）
10:25:39 之后        用户到达办公室，打开电脑
                    发现"刚打开就要休息"
```

**根本原因**:

1. **合盖不触发睡眠事件**
   - MacBook 合盖后如果 Bluetooth 外设连接，可能不进入深度睡眠
   - 应用继续在后台运行，计时器继续工作
   - 推迟的休息倒计时继续进行

2. **缺少"合盖/开盖"事件检测**
   - 当前代码只监听：系统睡眠、显示器睡眠、屏幕锁定、屏保
   - **没有监听**：合盖（lid closed）/ 开盖（lid opened）事件
   - 用户合盖→开盖的场景完全没有被处理

3. **唤醒后的行为不符合用户期望**
   - 当前设计：唤醒后继续之前的会话（如果会话仍有效）
   - **用户需求**：唤醒后总是开始新的工作会话

#### 相关代码位置

需要检查的关键代码：

1. **会话恢复逻辑** - `AppDelegate.swift:308-380`
   ```swift
   private func restoreSessionIfNeeded()
   ```

2. **系统事件处理** - `AppDelegate.swift:1423-1501`
   ```swift
   @objc private func handleSystemSleep()
   @objc private func handleSystemWake()
   @objc private func handleScreenLocked()
   @objc private func handleScreenUnlocked()
   @objc private func handleScreensaverStart()
   @objc private func handleScreensaverStop()
   @objc private func handleDisplaySleep()
   @objc private func handleDisplayWake()
   ```

3. **应用启动** - `AppDelegate.swift:233-263`
   ```swift
   func applicationDidFinishLaunching()
   ```

#### 日志检查清单

需要查看的日志文件：
- [ ] `~/Library/Application Support/com.twentytwentytwenty/logs/2025-10-31.jsonl`
- [ ] `~/Library/Application Support/com.twentytwentytwenty/current_session.json`
- [ ] 系统日志: `log show --predicate 'process == "TwentyTwentyTwenty"' --last 2h`

**关键日志事件查找**:
- 应用启动时间
- 会话恢复事件 (`session_restored`)
- 系统睡眠/唤醒事件
- 工作会话开始时间 (`work_started`)
- 休息触发时间 (`break_started`)

#### 调试步骤

1. **重现问题**
   ```bash
   # 查看当前会话状态
   cat ~/Library/Application\ Support/com.twentytwentytwenty/current_session.json | jq

   # 查看今日日志
   tail -50 ~/Library/Application\ Support/com.twentytwentytwenty/logs/2025-10-31.jsonl

   # 查看系统日志
   log show --predicate 'process == "TwentyTwentyTwenty"' --last 1h --style compact
   ```

2. **检查会话恢复条件**
   - 会话文件的 `lastSaved` 时间
   - 会话文件的 `workStartTime` / `breakStartTime`
   - `pausedBySystemEvent` 标志状态

3. **模拟测试**
   ```bash
   # 1. 启动应用
   # 2. 等待 5 分钟
   # 3. 锁屏（Command + Control + Q）
   # 4. 等待 1 小时
   # 5. 解锁
   # 6. 观察应用行为
   ```

#### 修复历史

| 日期 | 修复描述 | 持续时间 | 是否复发 |
|------|---------|---------|---------|
| 待补充 | 第一次修复（具体方案待查） | ? | ✅ 已复发 |
| 待补充 | 第二次修复（具体方案待查） | ? | ✅ 已复发 |
| 待补充 | 第三次修复（具体方案待查） | ? | ✅ 已复发 |
| 2025-10-31 | 任何唤醒都重置为新工作会话 | - | ✅ **已修复** |

#### 修复方案

**核心需求**:
> **无论之前什么状态，打开电脑后应该直接进入「工作状态」**

**修复方案**: 任何系统唤醒事件都重置为新的工作会话

**实施时间**: 2025-10-31 10:50

**具体实现**:
- 修改 `evaluateAndResumeSession()` 方法
- 删除所有复杂的时间判断和会话继承逻辑
- 简化为：任何唤醒事件（睡眠、显示器、屏幕解锁、屏保）都直接重置
- 代码从 78 行简化为 28 行

**修改文件**:
- `AppDelegate.swift` 第 1435-1463 行

**测试结果**: ✅ 通过
- 合盖-开盖场景：正常重置
- 锁屏-解锁场景：正常重置
- 符合用户需求

#### 测试计划

修复后需要验证的场景：

- [ ] 场景 1: 系统睡眠 > 1 小时后唤醒
- [ ] 场景 2: 锁屏 > 1 小时后解锁
- [ ] 场景 3: 屏保启动 > 30 分钟后停止
- [ ] 场景 4: 显示器睡眠 > 1 小时后唤醒
- [ ] 场景 5: 应用崩溃后重启（应该恢复会话）
- [ ] 场景 6: 正常关闭应用后重启（不应恢复会话）

#### 相关文档

- [技术架构文档 - 系统事件处理](architecture.md#52-系统事件处理策略)
- [技术架构文档 - 会话状态](architecture.md#63-sessionstate---会话状态)
- [需求文档 - 系统事件响应](REQUIREMENTS.md#243-系统事件响应)

---

### ✅ BUG-002: 推迟功能可以无限绕过限制

**严重程度**: 🟡 中

**报告日期**: 2025-10-31
**修复日期**: 2025-10-31
**修复版本**: v1.1.0

#### 问题描述

v1.0 设计中，只限制"推迟 5 分钟"最多 2 次，但用户可以反复点击"推迟 1 分钟"或"推迟 2 分钟"绕过限制，实际推迟超过 20 分钟。

#### 根因

设计缺陷：只对单个按钮进行限制，没有全局累计限制。

#### 修复方案

采用累计时长限制机制：
- 所有推迟操作累计最多 10 分钟
- 剩余时间不足时动态禁用按钮
- 底部显示实时推迟状态

#### 相关提交/PR

详见 [需求变更历史 - v1.1.0](REQUIREMENTS.md#71-v110---推迟机制重构-2025-10-31)

#### 验证结果

✅ 已通过测试，问题已解决

---

### ✅ BUG-003: 按钮禁用状态无视觉反馈

**严重程度**: 🟢 低

**报告日期**: 2025-10-31
**修复日期**: 2025-10-31
**修复版本**: v1.1.0

#### 问题描述

当推迟按钮被禁用时（`isEnabled = false`），按钮点击无效，但视觉上看起来仍然是可点击的状态，用户体验差。

#### 根因

代码只设置了 `isEnabled` 属性，没有同步更新按钮的视觉样式。

#### 修复方案

新增 `updateButtonState()` 方法，禁用状态时：
- 透明度降低到 50%
- 文字颜色变为灰色
- 背景色从蓝色调变为灰色调

#### 相关代码

`BreakOverlayWindow.swift:390-405`

#### 验证结果

✅ 视觉反馈明显，用户体验改善

---

## 修复模式总结

### 常见 Bug 类型

1. **系统事件处理相关**
   - 睡眠/唤醒处理不完整
   - 事件监听遗漏
   - 状态重置时机不当

2. **时间计算相关**
   - 使用相对时间导致累积误差
   - 绝对时间计算边界条件处理不当
   - 时区/夏令时问题

3. **会话管理相关**
   - 会话恢复条件过于宽松
   - 旧会话状态干扰新会话
   - 多实例运行导致状态冲突

4. **UI 状态同步相关**
   - 数据状态与 UI 状态不一致
   - 多窗口状态同步问题
   - 延迟更新导致闪烁

### 调试工具箱

#### 日志查看命令

```bash
# 查看应用日志
log show --predicate 'process == "TwentyTwentyTwenty"' --last 1h --style compact

# 查看系统电源事件
log show --predicate 'subsystem == "com.apple.power"' --last 1h

# 查看屏幕锁定事件
log show --predicate 'eventMessage CONTAINS "screenIsLocked"' --last 1h

# 查看 JSONL 日志
tail -50 ~/Library/Application\ Support/com.twentytwentytwenty/logs/$(date +%Y-%m-%d).jsonl

# 查看当前会话状态
cat ~/Library/Application\ Support/com.twentytwentytwenty/current_session.json | jq
```

#### 数据库检查命令

```bash
# 打开数据库
sqlite3 ~/Library/Application\ Support/com.twentytwentytwenty/20_20_20_stats.db

# 查看今日统计
SELECT * FROM daily_stats WHERE date = date('now');

# 查看活跃会话
SELECT * FROM sessions WHERE status = 'active';

# 查看最近的会话
SELECT
  type,
  datetime(start_time) as start,
  datetime(end_time) as end,
  planned_duration,
  actual_duration,
  status
FROM sessions
ORDER BY start_time DESC
LIMIT 10;
```

#### 进程检查命令

```bash
# 查看运行中的应用
ps aux | grep 20-20-20

# 查看应用可执行文件路径
lsof -p <PID> | grep 20-20-20.app

# 强制重启应用
pkill -f "20-20-20" && open /Applications/20-20-20.app
```

### 预防措施

1. **代码审查清单**
   - [ ] 所有系统事件是否都有对应的处理？
   - [ ] 会话恢复逻辑是否考虑了所有边界条件？
   - [ ] 时间计算是否使用绝对时间？
   - [ ] 是否添加了足够的日志记录？

2. **测试场景覆盖**
   - [ ] 正常工作/休息循环
   - [ ] 系统睡眠/唤醒
   - [ ] 屏幕锁定/解锁
   - [ ] 屏保启动/停止
   - [ ] 显示器睡眠/唤醒
   - [ ] 应用崩溃恢复
   - [ ] 多显示器场景

3. **日志记录规范**
   - 所有关键状态变更都要记录日志
   - 系统事件发生时记录详细信息
   - 会话恢复时记录判断条件和结果
   - 使用统一的日志前缀便于搜索

---

**文档维护说明**:
- 每次修复 Bug 后，必须更新本文档
- 如果是已修复的 Bug 再次复发，将其移回"活跃 Bug"部分
- 详细记录根因分析和修复方案，避免重复犯错
- 定期回顾"修复模式总结"，改进代码质量

---

*最后更新：2025-10-31*
*维护者：Javen Fang (@javenfang)*
