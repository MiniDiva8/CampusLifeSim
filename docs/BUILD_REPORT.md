# 构建与验证报告

日期：2026-07-23
版本：0.3.0-demo

## 环境

- Godot：4.7.1.stable.official.a13da4feb 标准版
- 渲染：Compatibility / OpenGL 3.3
- 目标：Windows Desktop x86_64 debug
- 导出模板：4.7.1.stable Windows debug/release 已安装

## 自动化结果

- 核心规则、难度、存档、图片清单与场景元数据测试：53 项通过。
- UI 流程冒烟测试：28 项通过，覆盖三个难度、难度存档、压力过载、半透明事件卡、真实场景文本、原始纹理尺寸与 EXIF 显示方向。
- 完整七天模拟：简易难度的平衡、学习、AI 三条路线，以及中等、困难的平衡路线，均在 33 个行动后到达项目展示并产生结局。
- 720p 视觉检查：使用 Windows OpenGL 3.3 和 NVIDIA GeForce RTX 5060 Laptop GPU 实际渲染；网球竖图完整显示，理综楼走廊方向正确，半透明卡片后照片清晰可见。
- 图片检查：65 张项目副本与用户原图逐张 SHA-256 一致，总计 313.16 MiB；未缩放、未重新编码、未二次压缩。
- 场景检查：操场八类照片和教学区八个具名空间均能显示对应名称；事件标题、正文、选项和结果支持当前场景替换。
- 项目运行：Godot 4.7.1 无界面运行无脚本错误、无对象泄漏。

## Windows 构建

- `CampusLifeSim.exe`、`CampusLifeSim.console.exe` 和 `CampusLifeSim.pck` 已成功生成。
- 文件大小：主程序 98.21 MiB，PCK 672.85 MiB，控制台包装器 0.05 MiB。PCK 变大来自 65 张原始分辨率照片的无损 Godot 纹理。
- 导出 PCK 使用 Godot 4.7.1 `--main-pack` 成功离线启动并正常退出，退出码为 0。
- 当前自动化环境两次直接启动新 EXE 时均被 Windows Application Control 拦截；文件没有网络来源标记，但属于未签名的 Godot debug 导出，因此本轮不声称完成直接 EXE 启动验证。
- 按项目约束未创建安装程序、未进行代码签名，也未修改系统安全策略。

请由项目所有者双击 EXE 进行人工验证；若同样出现 Application Control 阻止，应先确认本机组织或 Windows 安全策略，不要通过关闭安全功能绕过。PCK 已通过同一 Godot 4.7.1 运行时验证。
