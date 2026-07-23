# 构建与验证报告

日期：2026-07-23

## 环境

- Godot：4.7.1.stable.official.a13da4feb 标准版
- 渲染：Compatibility / OpenGL 3.3
- 目标：Windows Desktop x86_64 debug
- 导出模板：4.7.1.stable Windows debug/release 已安装

## 自动化结果

- 核心规则与图片清单测试：37 项通过。
- UI 流程冒烟测试：15 项通过。
- 完整七天模拟：平衡、学习、AI 依赖三条路线均在 33 个行动后到达展示并产生结局。
- 720p 视觉检查：主菜单校园照片、白天道路过渡、图书馆事件背景、校园地图和事件选择界面无裁切。
- 图片检查：64 张正式副本均完成方向校正，最长边不超过 1920 像素，运行时清单引用完整。
- 项目运行：Godot 4.7.1 无界面运行零错误、零对象泄漏。

## Windows 构建

- `CampusLifeSim.exe`、`CampusLifeSim.console.exe` 和 `CampusLifeSim.pck` 已成功生成。
- 文件大小：主程序 98.21 MiB，PCK 131.46 MiB，控制台包装器 0.05 MiB。
- 导出 PCK 使用 Godot 4.7.1 `--main-pack` 成功离线运行 30 帧。
- 新生成的 `CampusLifeSim.exe` 已直接成功离线运行 30 帧，退出码为 0。
- 按项目约束未创建安装程序、未进行代码签名，也未修改系统安全策略。

发布前仍建议在目标机器上双击 EXE，人工完整走一遍新游戏、地点切换、照片背景、存档和退出流程。
