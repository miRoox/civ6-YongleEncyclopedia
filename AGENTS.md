
## 实现约定

- 解缙沿用原版大作家的招募和创作机制，仅创作1部《永乐大典》，需要可用的文学巨作槽。`ActionCharges=0` 与原版大作家一致，创作次数由关联的巨作数量决定。
- 获取奖励对人类和 AI 均有效。每个文明首次拥有同一件巨作时触发一次；创作、考古、交易和城市转让均可获得奖励。移动槽位、读档或交易回原文明不会重复发奖。
- “全部科技”指当前规则集内有尤里卡、尚未研究完成且尚未触发尤里卡的科技，包括其他模组新增的科技。不为无尤里卡的科技或已完成科技发奖。
- 残篇从当前时代的有效科技中不重复抽取5项；不足5项时全部触发，不从其他时代补齐。《迭起兴衰》《风云变幻》采用世界时代，原版采用获取者的时代。
- 残篇的文物时代为文艺复兴，加入该时代的考古文物候选池，并非每次挖掘必定出现。发掘仍需满足原版考古条件（自然历史、考古博物馆、考古学家）；本模组不提前解锁整套考古系统。
- 常驻产出和旅游业绩使用原版巨作数据，受主题化、政策等原版加成影响。库存查询接口仅存在于 UI 环境：隐藏 UI 脚本扫描库存，通过 `EXECUTE_SCRIPT` 玩家操作通知 Gameplay，由 Gameplay 触发尤里卡和同步随机数，并保存防重复属性。若事件早于库存更新，下一次回合扫描时补发。联机由主机提交操作；联机同步仍需多人实测。

## 素材与依赖

无需额外模组或资料片，不再依赖“修复自定义巨作槽”。本模组使用原版文学槽、文物槽，不创建自定义槽位。

- 解缙：`ArtDefs/Yongle_GreatPeople.artdef` 显式绑定原版男性大作家模型、亚洲文化外观和文艺复兴时代；头像复用原版大作家图集。
- 《永乐大典》：复用原版文学巨作图标和书页展示背景。
- 残篇：内部类型改为 `GREATWORK_ARTIFACT_36433025`，复用 `ARTIFACT_25` 展示图及对应图标。原版巨作展示界面对文物名称有数值解析，旧名 `GREATWORK_YONGLE_FRAGMENT_1` 会导致展示脚本错误。
- `.Art.xml` 注册单位美术定义，ModBuddy 生成 `.dep`，通过 `UpdateArt` 加载；图标通过 `UpdateIcons` 单独加载。当前使用原版素材，未包含专属人物肖像、书籍插画或配音。

## ModBuddy 构建

1. 安装 Civilization VI Development Tools 和 Development Assets。
2. 用 ModBuddy 打开根目录的 `YongleEncyclopedia.civ6sln`。
3. 确认 Tools → Options → Civilization VI 中游戏、用户目录、SDK Assets 和 Asset Cooker 路径正确。用户目录应为包含 `Mods/`、`Saves/` 的游戏文档目录。本机实测为 `%USERPROFILE%\Documents\My Games\Sid Meier's Civilization VI`；配置、日志和缓存另在 `%LOCALAPPDATA%\Firaxis Games\Sid Meier's Civilization VI`，请勿混用。
4. Build Solution。正常输出包含 `Gameplay/`、`Text/`、`Icons/`、`Scripts/`、`UI/`、编译后的 `ArtDefs/Yongle_GreatPeople.artdef`、`YongleEncyclopedia.dep` 和 `YongleEncyclopedia.modinfo`。无需手工编辑生成的 `.modinfo`。修改动作注册后，完全退出并重新启动游戏，确保模组清单重新扫描。
5. 在游戏“额外内容”中启用本模组，开始新对局。本次修改了残篇内部类型并移除了旧效果定义，不支持用旧版本存档验证升级结果。

## 验证

在项目根目录运行：

```powershell
lua tests/test_acquisition.lua
python tests/validate_mod.py
```

Lua 测试用模拟游戏对象验证获取、随机抽取、时代限制、转让、城市转让、读档防重复、空候选池和原版规则回退，不代替游戏实测。Python 验证器只读打开本机 `DebugGameplay.sqlite`，在内存副本中执行 SQL，检查外键、数值、文本、图标、美术和项目引用。需要先启动过一局未启用本模组的游戏来生成该缓存；可用 `--gameplay-db`、`--game-dir` 指定其他路径，`--built-mod` 指定 ModBuddy 输出目录并检查打包结果。

若缓存来自已启用本版本的对局，可加 `--replace-existing`，先仅在内存副本中移除本模组当前行，再执行并验证 SQL；不会修改游戏缓存。

游戏内验收清单：

- 新开对局，确认解缙出现在文艺复兴大作家池，模型正常、说明可读，在空文学槽所在城市创作一次后退场。
- 确认《永乐大典》可展示、可移动，未完成科技收到尤里卡，所在城市获得基础 +10文化、+500科技、+10旅游。
- 发掘到残篇后，确认展示界面与图标正常；基础产出为 +50科技、+1文化、+3信仰、+2旅游；只触发当前时代尚未获得的最多5项尤里卡。
- 移动巨作并存档读档，确认不重复发奖；转让给未拥有过该件巨作的文明后确认其获得奖励，转让回来不重复发奖。城市转让同样检查。
- 检查当前用户目录下的 `Logs/Database.log`、`Modding.log`、`Lua.log`。确认本模组 SQL、图标、文本和脚本均被加载，没有对应文件的报错；Lua 日志应包含 `Yongle Encyclopedia: acquisition handlers loaded.`。

2026-10-19 已完成风云变幻单人实测：解缙招募、创作后退场，两件巨作的展示、实际产出、尤里卡、移槽和读档防重复均通过。残篇通过原版考古流程实际抽取获得。测试准备方式、数值、存档及尚未覆盖的场景见 [游戏内实测记录](tests/IN_GAME_TEST_REPORT.md)。联机、原版规则集、AI 自主获取、外交与城市转让仍需另行实测。
