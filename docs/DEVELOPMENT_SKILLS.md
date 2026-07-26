# 项目级设计 Skill

以下 Skill 只用于 Codex 的设计与评审流程，不会进入 Godot 运行时或 Windows 导出包。文件安装在 `.agents/skills/`，没有安装 npm 包、Godot 插件或系统依赖。

## OpenAI Frontend Skill

- 来源：https://github.com/openai/skills
- 路径：`skills/.curated/frontend-skill`
- 固定提交：`30444aed500c00c85294d12074f6e3ee794f808a`
- 说明：该目录后来在上游提交 `11c643813b4645ca9f25d49ca180697732e0141a` 中被移除，因此项目固定在删除前最后一个官方提交，不伪装为当前 `main`。
- 许可证：Apache License 2.0，全文保存在 `.agents/skills/frontend-skill/LICENSE.txt`。

## Microsoft Frontend Design Review

- 来源：https://github.com/microsoft/skills
- 路径：`.github/skills/frontend-design-review`
- 安装时 HEAD：`4f1db7ec55caf11e3b143c91220bd79a632bc55b`
- 许可证：MIT License；仓库版权声明为 `Copyright (c) Microsoft Corporation.`。

## Impeccable

- 来源：https://github.com/pbakaus/impeccable
- 路径：`.agents/skills/impeccable`
- 安装时 HEAD：`d272b9bd5dcfcb52d32482d192d06045ca31c503`
- 版本：Skill 元数据标记为 `4.0.2`。
- 许可证：Apache License 2.0；上游版权声明为 `Copyright 2025 Paul Bakaus`。
- 限制：其网页 DOM 检测器不适用于 Godot 原生 Control 树。本项目只使用其设计、构图、审核和原生适配原则，不执行网页自动修改流程。

## 使用边界

- Skill 源码不会被游戏脚本加载。
- 不调用 Skill 内的联网生成器或浏览器注入脚本。
- 不把 Web 框架、CSS 组件或 JavaScript 运行时带入 Godot。
- 上游升级必须单独审查并更新本文件中的提交号。
