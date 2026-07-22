# 构建与验证报告

日期：2026-07-22

## 环境

- Godot：4.7.1.stable.official.a13da4feb 标准版
- 渲染：Compatibility / OpenGL 3.3
- 目标：Windows Desktop x86_64 debug
- 导出模板：4.7.1.stable Windows debug/release 已安装

## 自动化结果

- 核心规则测试：29 项通过。
- UI 流程冒烟测试：11 项通过。
- 完整七天模拟：平衡、学习、AI 依赖三条路线均在 33 个行动后到达展示并产生结局。
- 720p 视觉检查：主菜单、校园地图、事件选择界面无裁切。
- 项目运行：Godot 4.7.1 无界面运行零错误、零对象泄漏。

## Windows 构建

- `CampusLifeSim.exe`、`CampusLifeSim.console.exe` 和 `CampusLifeSim.pck` 已成功生成。
- 文件大小：主程序 98.211 MiB，PCK 0.124 MiB，控制台包装器 0.048 MiB。
- 导出 PCK 使用 Godot 4.7.1 `--main-pack` 成功运行 60 帧。
- 本机 Application Control 策略拦截新生成的未签名 EXE，因此本机无法完成直接 EXE 启动验证。
- 按项目约束未修改系统安全策略、未创建安装程序、未进行代码签名。

该限制不表示 PCK、脚本或资源错误，但在比赛目标机器上仍需直接双击 EXE 做最终人工确认。
