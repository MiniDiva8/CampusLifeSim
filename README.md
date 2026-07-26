# 惊魂期末周

《惊魂期末周》是一款以山东大学中心校区和人工智能学院为背景、使用 Godot 4.7.1 与 GDScript 制作的校园人生模拟 Demo。玩家在七天期末周中安排学习、AI 课程项目、休息和社交，并面对 AI 工具带来的效率与判断风险。

## 运行环境

- Godot 4.7.1 标准版
- Windows x86_64
- 离线运行，无在线服务或付费依赖

## 启动游戏

通常可以运行 `builds/windows/CampusLifeSim.exe`。如果 Windows App Control 因为比赛构建尚未进行代码签名而阻止 EXE，请双击项目根目录的 `启动游戏（安全方式）.cmd`。该启动器不会关闭或绕过系统安全功能，只会调用本机已安装的官方签名 Godot 4.7.1，并通过 Godot 官方支持的 `--main-pack` 参数加载 `CampusLifeSim.pck`。

此替代启动方式仅适合当前开发电脑。正式对外分发时仍应使用受比赛电脑策略信任的代码签名证书签署 release 构建，或由比赛主办方/设备管理员将构建加入允许策略。

## 核心范围

- 七个游戏日，每天五个时段
- 六个可点击山大地点：中心校区学生公寓、蒋震图书馆、中心校区教学区、人工智能学院机房、齐园餐厅、风雨操场
- 65 张校园实景背景，按地点与昼夜道路分类随机展示，项目副本保留原始分辨率与文件质量
- 地点、事件与结算采用“独立照片舞台 + 交互面板”，自动识别横图和竖图并按原比例完整显示
- 固定考试、答疑、项目会议和彩排会按事件语义选择董明珠楼、理综楼、蒋震图书馆或机房照片
- 网球、游泳、篮球等运动会区分风雨操场、中心校区综合体育馆、室外网球场和室外田径场；理综楼、知新楼等教学场景会显示真实名称和对应叙述
- 进入地点前约两秒的道路滚动过渡，采用等比放大后的轻微平移，支持“减少界面动效”设置
- 14 类原创程序化交互音效，区分悬停、普通点击、确认、返回、选择、地点进入、危险操作和状态反馈
- Master、Music、SFX、UI、Event、Stress、Ambience 七层音频总线，可分别调节音乐、交互和校园环境音量
- 主菜单、校园总览、道路和六个地点拥有不同的原创程序化声景，并随白天、傍晚、深夜改变活动密度
- 道路声与目的地声在两秒路途过程中交叉淡化；高压力会叠加可独立关闭的低频身体反馈
- 主菜单、角色初始化、校园总览、事件、设置、暂停与结局使用统一的“山大夜航”Neo Glass 视觉体系
- 主信息面板采用分辨率无关的屏幕取样毛玻璃，按钮具有鼠标跟随聚光、悬停抬升与键盘焦点反馈；“减少界面动效”会关闭位移动画
- 校园实景照片始终位于独立清晰层，不参与玻璃模糊、不拉伸、不压缩，保证比赛展示时的辨识度
- 选项点击会在当前帧锁定重复输入并显示结算反馈；4000–5000 像素原图只加载一次并通过四张 LRU 缓存复用，道路图、目的地图和下一幕事件图使用后台线程读取
- 学习、项目、精力、压力、人物关系与隐藏 AI 依赖度
- 简易、中等、困难三档难度；难度会改变压力、精力与学业结算倍率
- 高压时使用长曝光照片触发“头晕眼花”危机选择
- 数据驱动事件、即时与延迟后果
- 一场人工智能专业核心课考试、一次 AI 课程项目展示和七种结局
- 单一自动存档与继续游戏

## 开发命令

```powershell
& "C:\Users\24578\Tools\Godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe" --editor --path .
& "C:\Users\24578\Tools\Godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe" --headless --path . --quit-after 180
& "C:\Users\24578\Tools\Godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe" --headless --path . --script res://tests/test_runner.gd
& "C:\Users\24578\Tools\Godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe" --headless --path . --script res://tests/audio_smoke.gd
& "C:\Users\24578\Tools\Godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe" --headless --path . --script res://tests/ambience_smoke.gd
& "C:\Users\24578\Tools\Godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe" --headless --path . --script res://tests/ui_smoke.gd
& "C:\Users\24578\Tools\Godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe" --headless --path . --script res://tests/full_run_simulation.gd
```

用户更新父级 `游戏场景图片/` 后，可重新复制并校验原图项目副本：

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
