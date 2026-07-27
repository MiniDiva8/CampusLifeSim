# 惊魂期末周

《惊魂期末周》是一款以山东大学中心校区和人工智能学院为背景、使用 Godot 4.7.1 与 GDScript 制作的校园人生模拟 Demo。玩家在七天期末周中安排学习、AI 课程项目、休息和社交，并面对 AI 工具带来的效率与判断风险。

## 运行环境

- Godot 4.7.1 标准版
- Windows x86_64
- 离线运行，无在线服务或付费依赖

## 启动游戏

当前开发电脑请双击项目根目录的 `启动游戏（安全方式）.cmd`，它会加载最新的 `builds/windows/CampusLifeSim.pck`。目录中的 EXE 仍是较早开发构建，且曾被 Windows App Control 阻止，不应作为本轮验收入口。安全启动器不会关闭或绕过系统安全功能，只会调用本机已安装的官方签名 Godot 4.7.1，并通过 Godot 官方支持的 `--main-pack` 参数加载游戏。

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
- 主菜单采用“期末周档案封面”：校园原图作为带图钉、日期戳和地点圈注的档案附图，功能入口改为档案目录索引，并以“启封档案”开始新一周
- 新游戏初始化采用双页路线档案，不再使用三列人格卡片；稳扎稳打、实干派、协调者分别显示核心风格、优势、短板、推荐行动和事件倾向
- 三条路线不是装饰标签：它们真实改变学习/项目/关系收益、行动压力以及学业、项目或 NPC 事件的出现优先级
- 校园总览采用原创纸质校园导览图：六个地点以不规则建筑轮廓呈现，道路、当前位置、选中路线、NPC 落点和截止日便签都位于同一地图语境
- 鼠标停在地图建筑上会即时展开纸质活动浮签，直接说明该地点可以进行的两项行动；点击后再固定路线与完整地点介绍
- 地点不再使用 2×3 等宽卡片；点击建筑后只展开一个底部地点说明和“前往这里”操作，再进入原有两秒校园路途
- 选择结算使用与事件页一致的“校园纪实回执”，保留当时的原比例照片、数值变化、自动存档状态和单一翻页操作
- 主菜单、路线初始化、事件页和校园地图已经统一到暖纸、山大红、档案批注与校园纪实排版；设置、暂停与结局仍保留兼容的玻璃组件
- 档案目录、路线页签、难度节点和地图建筑均保留鼠标悬停与键盘焦点反馈；减少界面动效设置会关闭页面进入位移
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
$godot = "C:\Users\24578\Tools\Godot\4.7.1\Godot_v4.7.1-stable_win64.exe"
Start-Process -FilePath $godot -ArgumentList @("--editor", "--path", (Get-Location))
Start-Process -FilePath $godot -ArgumentList @("--headless", "--path", (Get-Location), "--script", "res://tests/test_runner.gd") -WindowStyle Hidden -Wait
Start-Process -FilePath $godot -ArgumentList @("--headless", "--path", (Get-Location), "--script", "res://tests/audio_smoke.gd") -WindowStyle Hidden -Wait
Start-Process -FilePath $godot -ArgumentList @("--headless", "--path", (Get-Location), "--script", "res://tests/ambience_smoke.gd") -WindowStyle Hidden -Wait
Start-Process -FilePath $godot -ArgumentList @("--headless", "--path", (Get-Location), "--script", "res://tests/ui_smoke.gd") -WindowStyle Hidden -Wait
Start-Process -FilePath $godot -ArgumentList @("--headless", "--path", (Get-Location), "--script", "res://tests/full_run_simulation.gd") -WindowStyle Hidden -Wait
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
