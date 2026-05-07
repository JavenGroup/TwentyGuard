# Chinese Channels

Use this for Chinese community launch notes. Prefer Chinese UI screenshots and a
practical usage story over a direct translation of the English announcement.

## Suitable Angle

```text
给那些明知道该休息、但总会继续盯着屏幕的 Mac 用户。
```

The sharper story:

- 不是普通通知提醒，而是更偏强制执行。
- 可以推迟，但不能无限推迟。
- 统计页先给今天的判断，而不是只堆数字。
- 晚上可以逐步收紧，到点后完全禁用屏幕。
- 核心功能不需要网络，数据保存在本机。

## Short Post Draft

我做了一个 macOS 菜单栏小工具 TwentyGuard，给那些“知道该休息，但总会继续盯着屏幕”的人。

它基于 20-20-20 护眼法则，但不是普通通知提醒，而是更偏强制执行：

- 到点后显示全屏休息遮罩，支持多显示器；
- 可以推迟 1、2、5 分钟，但有累计上限，不能无限拖；
- 支持自定义工作/休息节奏；
- 统计页会先告诉你今天的用眼节奏判断，再看完成率、推迟情况和近 7 天趋势；
- 晚上可以开启夜间禁用，先逐步缩短可用时间，到设定时间后完全禁用屏幕，早上自动恢复。

核心功能不需要网络，设置、日志和统计都保存在本机。当前 v1.5.0 已经有签名和公证过的 macOS DMG。

它不是医疗软件，也不承诺治疗眼疲劳。它更像一个小而严格的 Mac 工具：帮你把“该休息了”这件事真正执行下来。

## Longer Story Draft

我一直觉得护眼提醒的问题不在于“不知道 20-20-20 法则”，而在于每次提醒出现时，人都会和自己讨价还价：再编译一次、再回一条消息、再看一会儿视频。

所以 TwentyGuard 的重点不是做一个更漂亮的提醒通知，而是给这个讨价还价加一点阻力。

它平时只是一个菜单栏应用。到点后，会用全屏遮罩提醒休息；你可以推迟，但推迟有累计上限；统计页会告诉你今天是不是真的完成了休息，还是一直在拖延。晚上如果需要更硬的边界，也可以开启夜间禁用，让屏幕使用时间逐步收紧，最后到点禁用。

我希望它的气质是：界面克制，行为严格。本地优先，不做复杂账号体系，也不把护眼包装成玄乎的健康承诺。

## Recommended Chinese Screenshots

- 中文菜单栏主菜单。
- 中文休息遮罩，显示推迟按钮。
- 中文统计报告，显示“今日判断”。
- 中文夜间禁用遮罩。

## Channels To Consider

Verify current rules before posting.

- V2EX: likely best with a transparent maker note and Mac utility framing.
- 少数派: better after screenshots and a more polished usage story are ready.
- 即刻 / X / Threads: short version with one strong screenshot.
- GitHub README_CN: keep it factual and download-focused.

## Avoid

- 不要说“治疗眼疲劳”“改善视力”“治疗失眠”。
- 不要把本地优先说成绝对隐私保证。
- 不要只发下载链接，要解释为什么这个工具和普通提醒不一样。
- 不要在没有中文截图时做大范围中文推广。
