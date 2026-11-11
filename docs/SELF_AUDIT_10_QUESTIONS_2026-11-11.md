# 第一次主动代码纠察报告

审查日期：2026-11-11
审查分支：ew/loot-build-mvp
审查方式：GitHub 源码树、场景资源、脚本、主题字体、Android 导出工作流静态审查。
重要限制：本次是静态审查，没有运行 Godot 编辑器、没有启动服务器、没有安装 APK 实机测试。因此凡涉及运行时表现均标记为“待实测”，不虚报通过。

## 对自己提出的10个问题及答案

### 1. 玩家从启动到创建角色，是否能全程使用简体中文？
**不通过。** `presets/gui/Login.tscn` 中 Name、Password、Confirm Password、Email、Reset Code、Remember me 仍为英文；`sources/gui/Login.gd` 的认证错误提示也有英文。角色创建场景 `presets/gui/Character.tscn` 仍有 Enter Character Name、Attributes、Strength、Vitality、Agility、Endurance、Concentration、Stats、Location、Previous、Next、Traits、Hairstyle、Hair Color、Race、Ethnicity、Skin Tone 等英文。不能称为中文版本。

### 2. 性别是否真的有男女两个选项，而不是只有女性？
**源码中存在男女切换逻辑，但界面交互不够直观，运行时尚未验证。** `Traits.gd` 用左右箭头循环切换“男/女”，场景中同时有 Gender 标签和动态值。它不是两个并排、直接可点的按钮。必须在手机上验证箭头触控区域、预览模型变化、提交数据与重新登录后的结果。建议改为明显的“男 / 女”双选控件。

### 3. 默认性别是否符合要求，随机外观会不会覆盖？
**静态代码显示随机外观函数将 genderValue 设为 MALE，缺失角色信息时也补为 MALE。** 但必须确认创建界面首次进入时一定调用 Randomize()，以及创建按钮实际读取的是 traitsPanel.genderValue。源码存在保存预览时从 traitsPanel.genderValue 写入角色数据的路径。需跑通首次创建、随机外观、切换性别、创建、重进四条路径。

### 4. 中文字体是否可靠，所有设备是否能显示中文？
**高风险，未通过。** 默认主题 `DefaultTheme.tres` 将默认字体设为 `alagard-16.ttf`，小标签使用 `romulus-16.ttf`。项目树存在 DejaVuSans，但当前主题没有显示它作为中文 fallback。必须确认字体字形覆盖、配置 fallback 并实机检查缺字方框、乱码、标点和字体溢出。仅把英文文本替换成中文不能保证显示正常。

### 5. 背包是否已经中文化，物品操作是否清楚？
**不通过。** `Inventory.tscn` 仍有 Inventory、Drop、Unequip、Equip、Use、Cancel、Confirm、Equipment、Modifiers、Capacity、Weight、Slots 等英文。还需验证“使用/装备/卸下/丢弃/确认”是否触屏可操作、操作后数据是否变化，不能只改标签。

### 6. 设置页和角色属性页是否中文化？
**不通过。** `Settings.tscn` 包含 Preset、PC、Mobile、Visual、Fullscreen Mode、Window Resolution、Scaling、Action Overlay、Effect、Lighting、Volume、Music、Combat、Alerts、Change Password、Bug Reports 等大量英文。 `Stats.tscn` 包含 Strength、Vitality、Agility、Endurance、Concentration、Available points、Experience、Health、Mana、Stamina、Weight、Money、Attack、Defense、Crit Rate 等英文。

### 7. 技能、任务、对话、商店和系统提示是否有统一翻译方案？
**未发现项目级翻译资源或 locale 配置。** 当前审查树中没有实际翻译表；此前新增的 QA 文档不是本地化实现。应先建立统一术语表和 Godot TranslationServer/CSV 翻译资源或统一文本数据方案，再按界面与数据表逐模块覆盖，避免散落硬编码、反复改词。

### 8. Android 构建链路是否存在，是否能证明 APK 可安装？
**有自动构建工作流，但本次未执行构建。** `.github/workflows/android-debug.yml` 定义 Android Debug APK 导出并检查 APK 文件非空、ZIP 完整。需要检查当前分支最新 workflow run 的结果，安装到手机测试启动、触控、字体、存档和网络。工作流文件存在不等于构建成功，更不等于实机通过。

### 9. 新增装备掉落系统是否真正连上原有系统，而不是只写了方案文档？
**当前本分支已提交的是开发计划文档，尚不能视为功能代码已完成。** 上游代码已有 MonsterAgent 掉落、WorldDrop 拾取、Inventory 装备/存档基础能力；但本轮计划中的中文怪物数据、铜币掉落、精英装备掉落权重、装备词条持久化与套装效果尚未完成验证。尤其随机词条必须持久化到装备实例并在读档后保持，不能只做 UI 展示。

### 10. 每次交付前是否检查异常情况和手机真实操作？
**当前流程不合格，需要建立发布门禁。** 必测：网络断开、登录错误、重名、空名称、背包满、金币不足、装备槽冲突、死亡掉落、存档中断、快速连续点击、手机键盘遮挡、按钮触控区域、低分辨率文字溢出。每次交付都应提供静态扫描结果、构建链接/状态、实机测试结果和未解决问题。

## 本次审查发现的明确问题

| 严重级别 | 问题 | 证据/位置 | 处理要求 |
|---|---|---|---|
| P0 | 登录和角色创建流程英文残留 | presets/gui/Login.tscn; Character.tscn; Login.gd; Character.gd | 首屏流程全汉化 |
| P0 | 性别选择是箭头轮播，不是直观双选 | Character.tscn Gender 节点；Traits.gd | 改成男/女双选控件并做创建/读档验证 |
| P0 | 默认字体没有明确中文 fallback | DefaultTheme.tres 默认 alagard、SmallLabel romulus | 配置中文字体与 fallback，实机验字 |
| P1 | 背包界面仍大量英文 | presets/gui/Inventory.tscn | 全部操作标签和物品详情汉化 |
| P1 | 设置页仍大量英文 | presets/gui/Settings.tscn | 汉化标题、标签、tooltip、弹窗 |
| P1 | 属性面板仍大量英文 | presets/gui/Stats.tscn | 统一属性术语 |
| P1 | 未建立项目级翻译表 | 当前树无翻译资源 | 建立统一本地化基础设施 |
| P1 | 装备随机词条持久化尚未实现/验证 | 现有 Item 实例结构与 Sprint 文档风险项 | 先设计存档兼容方案再开发 |
| P1 | 本轮游戏玩法代码尚未交付 | 本轮新增主要是 Sprint 文档 | 不把计划当作已完成代码 |
| P1 | Android 仅有工作流配置，尚无本轮实机证据 | android-debug.yml | 构建并在真实手机上验收 |

## 下一轮整改顺序（避免反复返工）

1. 先建立中文术语表、翻译资源和字体 fallback；这是全局基础，先做避免每个界面重复返工。
2. 一次性处理登录、角色创建、男女双选与属性页；同步做两种性别创建/保存/重进测试。
3. 汉化背包、装备、技能、任务、商店、设置、通知和异常提示。
4. 完成静态英文可见文本扫描，区分允许保留的技术标识与玩家可见文本。
5. 构建 Android APK，在手机上按完整新手流程验收。
6. 基础体验通过后再接入掉落、装备词条、套装；每个系统都要验证真实数据变化与存档。

## 交付门槛

本报告中 P0 全部修复并通过 Android 实机验证之前，不应对外称“中文版已完成”或交付为正式测试版本。P1 未完成项必须明确列出，不得隐藏。
