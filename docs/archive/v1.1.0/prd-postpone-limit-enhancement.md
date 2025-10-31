# PRD: 推迟机制优化 - 累计时长限制

> **文档类型**: Feature Enhancement / Bug Fix
> **优先级**: Medium
> **预计工作量**: 0.5 人天
> **创建日期**: 2025-10-31
> **作者**: Javen Fang (@javenfang)

---

## 📋 问题描述

### 当前问题

用户在休息窗口可以反复推迟休息，导致护眼效果大打折扣：

**当前限制规则**：
- 推迟 1 分钟：无限制
- 推迟 2 分钟：无限制
- 推迟 5 分钟：最多 2 次

**问题场景**：
```
用户操作序列：
1. 推迟 1 分钟 (累计: 1min)
2. 推迟 1 分钟 (累计: 2min)
3. 推迟 2 分钟 (累计: 4min)
4. 推迟 5 分钟 (累计: 9min)
5. 推迟 5 分钟 (累计: 14min)
6. 推迟 1 分钟 (累计: 15min)
7. 推迟 2 分钟 (累计: 17min)
... 可以无限推迟下去
```

**核心问题**：
- ❌ 只限制"5分钟推迟次数"不够，用户可以通过 1/2 分钟推迟绕过限制
- ❌ 累计推迟时间可能远超工作时长，完全失去护眼意义
- ❌ 违背应用设计初衷：强制用户休息保护眼睛

---

## 🎯 解决方案

### 新限制规则

**改为累计时长限制**：
- **所有推迟操作累计最多 10 分钟**
- 超过 10 分钟后，强制进入休息，不允许继续推迟

### 实施细节

**计算逻辑**：
```
totalPostponedTime = 0

每次推迟时：
  if (totalPostponedTime + postponeMinutes > 10) {
    // 禁用所有推迟按钮，或显示"已达推迟上限"
    return
  }
  totalPostponedTime += postponeMinutes
  updateButtonStates()
```

**按钮状态**：
- 推迟累计 < 10 分钟：所有按钮可用（但需考虑剩余时间）
- 推迟累计 = 10 分钟：所有推迟按钮禁用
- 剩余可推迟时间 < 1 分钟：推迟 1/2/5 分钟按钮都禁用

**用户反馈**：
- 按钮文字显示剩余可推迟时间：
  ```
  推迟 1 分钟 (⌘1) - 剩余: 8min
  推迟 2 分钟 (⌘2) - 剩余: 8min
  推迟 5 分钟 (⌘5) - 剩余: 8min
  ```
- 或在窗口底部显示：
  ```
  已推迟 2 分钟，剩余可推迟 8 分钟
  ```

**边界情况**：
1. 剩余 3 分钟时，点击"推迟 5 分钟" → 禁止（超过上限）
2. 剩余 1 分钟时，点击"推迟 2 分钟" → 禁止（超过上限）
3. 累计 10 分钟后 → 强制休息，清空累计（完成休息后重置）

---

## 📐 技术实现

### 涉及文件

1. **[AppDelegate.swift](../Sources/TwentyTwentyTwenty/AppDelegate.swift)**
   - 添加 `totalPostponedTime: TimeInterval` 追踪累计推迟时间
   - 修改 `postponeBreak(minutes:)` 方法，检查累计时长
   - 完成休息后重置 `totalPostponedTime = 0`

2. **[BreakOverlayWindow.swift](../Sources/TwentyTwentyTwenty/BreakOverlayWindow.swift)**
   - 添加 `setRemainingPostponeTime(_ minutes: Int)` 方法
   - 更新按钮文字显示剩余可推迟时间
   - 根据剩余时间动态禁用/启用按钮

### 关键代码逻辑

**AppDelegate 改动**：
```swift
// 添加属性
private var totalPostponedTime: TimeInterval = 0  // 累计推迟时间（秒）
private let maxTotalPostponeTime: TimeInterval = 10 * 60  // 最多推迟10分钟

// 修改推迟方法
private func postponeBreak(minutes: Int) {
    let postponeSeconds = TimeInterval(minutes * 60)

    // 检查是否超过累计上限
    if totalPostponedTime + postponeSeconds > maxTotalPostponeTime {
        print("⚠️ 已达推迟上限，无法继续推迟")
        return
    }

    // 累加推迟时间
    totalPostponedTime += postponeSeconds

    // 更新窗口显示剩余可推迟时间
    let remainingMinutes = Int((maxTotalPostponeTime - totalPostponedTime) / 60)
    for overlay in breakOverlays {
        overlay.setRemainingPostponeTime(remainingMinutes)
    }

    // ... 原有推迟逻辑
}

// 完成休息后重置
private func completeBreakSession() {
    // ... 原有逻辑
    totalPostponedTime = 0  // 重置累计推迟时间
}
```

**BreakOverlayWindow 改动**：
```swift
func updatePostponeStatus(used: Int, remaining: Int) {
    // 更新按钮禁用状态
    postpone1Button.isEnabled = (remaining >= 1)
    postpone2Button.isEnabled = (remaining >= 2)
    postpone5Button.isEnabled = (remaining >= 5)

    // 更新底部状态文字
    if let localizer = localizer {
        let statusText = String(format: localizer("postpone_status"), used, remaining)
        statusLabel.stringValue = statusText
    }
}
```

**需要在 BreakOverlayWindow 添加**：
- `statusLabel: NSTextField` - 窗口底部的状态提示标签
- 布局：在按钮下方居中显示，字体 14pt，颜色 secondaryLabelColor

---

## 🧪 测试用例

### 基本功能测试

| 测试场景 | 操作步骤 | 预期结果 |
|---------|---------|---------|
| **正常推迟** | 1. 推迟1分钟 <br> 2. 推迟2分钟 <br> 3. 推迟5分钟 | 底部显示"已推迟 8 分钟，剩余 2 分钟"<br>5分钟按钮禁用 |
| **达到上限** | 累计推迟10分钟后 | 所有推迟按钮禁用<br>底部显示"已推迟 10 分钟，剩余 0 分钟" |
| **按钮禁用** | 剩余3分钟时 | 5分钟按钮禁用（灰色）<br>1/2分钟按钮可用 |
| **边界情况1** | 剩余4分钟时点击"推迟5分钟" | 按钮已禁用，无法点击 |
| **边界情况2** | 剩余1分钟时点击"推迟2分钟" | 按钮已禁用，无法点击 |
| **重置测试** | 完成休息后进入下一个休息周期 | 累计推迟时间重置为0<br>所有按钮恢复可用 |
| **数据库验证** | 查询 sessions 表 | `total_postpone_duration` 字段正确记录累计秒数 |

### 用户体验测试

| 测试项 | 验证点 |
|--------|--------|
| **底部状态显示** | 是否正确显示"已推迟 X 分钟，剩余 Y 分钟" |
| **按钮状态** | 剩余时间不足时，对应按钮是否变灰禁用 |
| **多语言** | 各语言下底部提示文字是否正确 |
| **多屏幕** | 所有屏幕窗口状态和文字是否同步 |
| **视觉反馈** | 按钮禁用时的视觉效果是否明显 |

---

## 🎨 UI 设计

### 确定方案：方案 A + 方案 C

**按钮显示**（保持简洁）：
```
推迟 1 分钟 (⌘1)
推迟 2 分钟 (⌘2)
推迟 5 分钟 (⌘5)  [剩余不足5分钟时禁用变灰]
```

**底部提示**（显示推迟状态）：
```
[窗口底部居中]
已推迟 2 分钟，剩余可推迟 8 分钟
```

**按钮禁用逻辑**：
- 剩余可推迟时间 < 5 分钟 → "推迟 5 分钟"按钮禁用
- 剩余可推迟时间 < 2 分钟 → "推迟 2 分钟"按钮禁用
- 剩余可推迟时间 < 1 分钟 → "推迟 1 分钟"按钮禁用
- 剩余可推迟时间 = 0 → 所有按钮禁用

**优势**：
- ✅ 按钮保持简洁，不因文字变长而变形
- ✅ 底部提示清晰展示当前状态
- ✅ 按钮禁用状态直观反映限制

---

## 📊 影响评估

### 用户影响

**正面影响**：
- ✅ 强化护眼效果，避免过度推迟
- ✅ 用户更清楚推迟限制（剩余时间可见）
- ✅ 符合应用设计初衷

**可能的负面反馈**：
- ⚠️ 部分用户可能觉得限制"太严格"
- ⚠️ 需要在 README 中说明新的限制规则

**缓解措施**：
- 在设置中提供"宽松模式"选项（可选，未来功能）
- 在 README 和应用首次启动时说明护眼规则

### 技术影响

- **代码改动**: 小（~50 行）
- **向后兼容**: 是（不影响现有数据）
- **性能影响**: 无
- **测试工作量**: 低

---

## 📅 实施计划

### 开发任务

| 任务 | 预计时间 | 负责人 |
|------|---------|--------|
| 1. 修改 AppDelegate 推迟逻辑 | 1 小时 | 开发者 |
| 2. 更新 BreakOverlayWindow UI | 1 小时 | 开发者 |
| 3. 多语言文本更新 | 0.5 小时 | 开发者 |
| 4. 单元测试和手动测试 | 1 小时 | 开发者 |
| 5. 更新文档 (README/REQUIREMENTS) | 0.5 小时 | 开发者 |

**总计**: ~4 小时 (0.5 人天)

### 发布计划

- **版本**: v1.1.0
- **发布类型**: Minor Update
- **Changelog 条目**:
  ```
  ### Changed
  - 推迟机制优化：改为累计总时长限制（最多10分钟），防止过度推迟
  - 推迟按钮显示剩余可推迟时间
  ```

---

## ✅ 已确认的设计决策

**Q1: 10 分钟上限**
> ✅ 确认使用 10 分钟作为累计推迟上限
> - 默认工作 20 分钟，推迟 10 分钟 = 50% 工作时长（合理）
> - 自定义最长 60 分钟工作，10 分钟仍是合理的紧急缓冲

**Q2: UI 方案**
> ✅ 确认采用：**方案 A（简洁按钮）+ 方案 C（底部提示）**
> - 按钮文字保持简洁，不显示剩余时间
> - 窗口底部显示"已推迟 X 分钟，剩余 Y 分钟"
> - 按钮根据剩余时间动态禁用

**Q3: 数据库存储**
> ✅ 已有完善设计，无需修改：
> - `sessions.total_postpone_duration` 字段已存在（累计推迟秒数）
> - `postpone_events` 表已记录每次推迟的详细事件
> - 现有的 `recordPostpone()` 方法已在使用

**Q4: 多语言处理**
> 在本地化字典中添加：
> ```swift
> "postpone_status": "已推迟 %d 分钟，剩余可推迟 %d 分钟"  // 中文
> "postpone_status": "Postponed %d min, %d min left"      // 英文
> ```

---

## 📚 参考资料

- [当前实现: AppDelegate.swift:1301-1356](../Sources/TwentyTwentyTwenty/AppDelegate.swift#L1301-L1356)
- [当前实现: BreakOverlayWindow.swift:354-380](../Sources/TwentyTwentyTwenty/BreakOverlayWindow.swift#L354-380)
- [需求文档: REQUIREMENTS.md](REQUIREMENTS.md#213-推迟功能)
- [架构文档: architecture.md](architecture.md#43-推迟逻辑)

---

**文档状态**: ✅ Ready for Implementation
**下一步**: 等待确认后开始实施
