# 惊魂期末周

《惊魂期末周》是一款使用 Godot 4.7.1 和 GDScript 制作的校园人生模拟 Demo。玩家在七天期末周中安排学习、项目、休息和社交，并面对 AI 工具带来的效率与判断风险。

## 运行环境

- Godot 4.7.1 标准版
- Windows x86_64
- 离线运行，无在线服务或付费依赖

## 核心范围

- 七个游戏日，每天五个时段
- 六个可点击校园地点
- 64 张校园实景背景，按地点与昼夜道路分类随机展示
- 进入地点前约两秒的道路滚动过渡，支持“减少界面动效”设置
- 学习、项目、精力、压力、人物关系与隐藏 AI 依赖度
- 简易、中等、困难三档难度；难度会改变压力、精力与学业结算倍率
- 高压时使用长曝光照片触发“头晕眼花”危机选择
- 数据驱动事件、即时与延迟后果
- 一个考试、一次项目展示和七种结局
- 单一自动存档与继续游戏

## 开发命令

```powershell
& "C:\Users\24578\Tools\Godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe" --editor --path .
& "C:\Users\24578\Tools\Godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe" --headless --path . --quit-after 180
& "C:\Users\24578\Tools\Godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe" --headless --path . --script res://tests/test_runner.gd
& "C:\Users\24578\Tools\Godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe" --headless --path . --script res://tests/ui_smoke.gd
& "C:\Users\24578\Tools\Godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe" --headless --path . --script res://tests/full_run_simulation.gd
```

用户更新父级 `游戏场景图片/` 后，可重新生成经过方向校正和尺寸优化的项目副本：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\tools\import_user_backgrounds.ps1"
```

运行时图片清单位于 `data/backgrounds.json`；分类变化时需同步更新该文件。

## 隐藏演示预设

预设不显示在正式 UI 中，仅供比赛录屏和复现路线：

```powershell
& ".\builds\windows\CampusLifeSim.exe" -- --demo-preset=balanced
```

可用值：`balanced`、`study`、`project`、`ai`、`pressure`、`presentation`。

第三方代码来源与许可见 `docs/ASSET_SOURCES.md` 和 `third_party/`。
