# 素材与第三方来源

## 正式游戏素材

- 校园地图、图标和 UI 使用 Godot 原生控件与项目自制矢量/程序化图形。
- 地点、菜单和道路背景使用项目所有者于 2026-07-23 提供的校园照片，原始来源目录为父级工作区的 `游戏场景图片/`。
- 项目内的 65 张正式副本与用户原图逐字节一致，并使用 SHA-256 校验；不缩放、不重新编码、不进行 JPEG 二次压缩。
- 分类包括宿舍、图书馆、教学楼、实验室、食堂、操场、白天道路、夜晚道路、菜单界面和压力过载效果。
- 父级目录根部的长曝光光轨照片由用户明确指定为高压“头晕眼花”显化背景，项目副本为 `assets/backgrounds/effects/stress_overload.jpg`。
- 照片由用户提供并指定用于本项目；公开分发前，项目所有者仍应确认照片中可识别人物及场所的肖像权、隐私和拍摄许可。
- 未下载或使用来源不明的图片、音乐、字体或音效。

## 第三方代码

- Maaack/Godot-Game-Template v1.4.7，MIT License。
- 上游仓库：https://github.com/Maaack/Godot-Game-Template
- 仅选择性复用通用菜单、加载、暂停与音频代码；许可证全文保存在 `third_party/Maaack-Godot-Game-Template/LICENSE.txt`。

## 图片导入方式

- `tools/import_user_backgrounds.ps1` 从父级 `游戏场景图片/` 读取原图并原样复制到 `assets/backgrounds/`，复制后逐张核对 SHA-256。
- 导入脚本不覆盖、改名或删除父级原图。
- Godot 不会自动应用这些 JPEG 的 EXIF 方向，因此原文件保持不变，游戏显示层依据 `data/backgrounds.json` 中的方向元数据旋转画面。
- 运行时清单同时记录图片分类、真实场景名称和方向；新增或移除照片时需要同步更新清单。
