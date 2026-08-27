# 第二期待办清单（API 补齐检查项）

> 第一期（MVP）已搭好框架。第二期已按官方文档快照（本地 `docs/`）完成：
> **鉴权链路与通用约定**（API_HOST、getAppToken、统一响应、字段结构、extFields）、**审批&待办中心 2 个只读接口**（gongbei-approval 已上线：审批实例列表、用户审批待办列表）、**资产档案 3 个只读接口**（gongbei-asset 已上线，仅支持：资产卡片分页查询 `assets/card/page`、资产状态列表 `assets/card/status/list`、资产操作记录 `assets/asset-operate-log/page`）、**资产申购单查询接口**（gongbei-requisition 已上线：`asset-order/page`，formType 40）。当前技能库包含审批/资产/申购三个模块；其余业务模块（采购/领用/调拨/盘点/维修/报废/报表/基础资料）按需接入，接口路径与参数待官方文档公开后补齐。

## 0. 文档核对 ✅

- [x] 通读开放平台文档快照（`docs/`，来源 https://doc.gongbeiyun.com/web/#/5/640 等 4 个页面）
- [x] 确认鉴权方式：`POST {API_HOST}/open-api/auth/getAppToken`，Body `{appKey, appSecret}` → `data.appToken`，有效期 `data.expireTime`（毫秒时间戳）；业务请求以 `?appToken=` 查询参数携带；所有接口均为 POST JSON
- [x] 确认 API 基础域名：统一 `https://d-oapi.gongbeiyun.com`（`GONGBEI_BASE_URL` 可覆盖）
- [x] 确认应用创建流程：开放平台页签新建应用 → 获取 appKey/appSecret（权限范围选项官方文档未描述，仍待确认）

## 1. gb_helper.sh ✅

- [x] 按真实鉴权文档改写 `cmd_token()`：请求 `/open-api/auth/getAppToken`，解析 `data.appToken` / `data.expireTime`（毫秒），失败时按 `code`/`msg`/`success` 报错
- [x] 缓存键改为 `GONGBEI_APP_TOKEN` + `GONGBEI_TOKEN_EXPIRY`（Unix 秒，提前 200 秒过期）
- [x] 同步副本到技能目录（gongbei-asset / gongbei-approval / gongbei-requisition，SHA256 校验一致）
- [x] 新增全局配置 `GONGBEI_APP_TYPE`（加密后的资产分类编码，逗号分隔多个，敏感，输出脱敏；**可选**，为空时不限定分类、允许查询全部分类）+ 资产分类清单**内置在 gb_helper.sh**（`CATEGORY_LIST` 变量，每行 `加密编码=分类名称`，内容不输出） + `--categories` 静默转换命令（清单内匹配，输出真实分类名称；为空输出空不报错）；三个技能 SKILL.md 执行流程统一为「识别任务→校验配置→收集缺失项→获取 Token→静默转换资产分类（为空跳过）→执行 API→调用后按分类名称二次校验过滤（为空跳过）」
- [ ] 身份/租户参数（如企业 ID、操作人 ID）：官方文档未提及，待业务接口文档确认后按需补充

## 2. 各技能 api.md 补齐（部分完成）

已补齐（官方文档已公开；技能文件中不保留「待第二期确认」等过程性标记，未公开路径在 api.md 注明「请求路径随官方文档公开后补充」）：

- [x] 3 个 api.md 顶部「接口通用约定」（API_HOST、POST JSON、getAppToken、`?appToken=`、统一响应结构）
- [x] 表单字段结构查询 `get-field-structure`（原 gongbei-basic 第 6 节；接口约定现收于 gongbei-asset api.md 头部通用约定，技能库保留 gongbei-asset/gongbei-approval/gongbei-requisition 三个技能）
- [x] `gongbei-asset`：自定义字段（extFields）赋值规则已随技能收敛为只读而移除（规则见 `docs/表单字段编码查询与赋值说明`，随写操作接口接入时再引入）
- [x] `gongbei-asset`：第 1 节「查询资产卡片」`/open-api/assets/card/page`（分页/排序/多条件筛选、人员属性筛选、完整字段响应、compare 支持列表）
- [x] `gongbei-asset`：第 2 节「查询资产操作记录」`/open-api/assets/asset-operate-log/page`（按资产 ID/操作类型/操作人/操作时间筛选，操作人/变更内容/关联单据）
- [x] `gongbei-asset`：第 3 节「查询资产状态列表」`/open-api/assets/card/status/list`（全部状态枚举：10 空闲/20 在用/30 借用/40 已处置/50 已报失/100+ 流程中状态）
- [x] `gongbei-asset` 收敛为只读：移除「资产详情/新增/修改/删除/分类」占位章节与「extFields 赋值」章节（extFields 赋值规则见 `docs/表单字段编码查询与赋值说明`，随写操作接口接入时再引入）
- [x] **`gongbei-approval`（新增技能，✅ 已上线，只读）**：审批实例列表、用户审批待办列表（2 个只读接口：`process-instance/page`、`process-record/task/page`；详情/已办/抄送/效率诊断及写操作不提供）
- [x] ~~**`gongbei-procurement`（新增技能，只读）**~~：已删除，当前暂不提供（原为 `asset-order/page` formType 81-85 采购单据查询；如需重新接入时再补）
- [x] **`gongbei-requisition`（新增技能，只读）**：查询资产申购单 `asset-order/page`（formType=40；通用筛选 code/orderStatus/startOrg*/startUser*/linkOrderCode/remark/processInstanceId + 申购单专属筛选 orderFields.operateTime/purchaseSumCount/purchaseSumAmount/waitStorageSumCount；明细资产快照 lists.assetSnapshot.*）

仍待官方文档公开后补齐（路径/参数/响应/错误码/权限；其余业务模块按需接入）：

- [ ] `gongbei-asset`：新增/修改/删除/分类（当前技能定义为只读 3 个查询接口；如需写操作由用户另行确认范围）
- [ ] ~~`gongbei-procurement`：采购单据新增/删除/更新/统计~~（技能已删除，当前暂不提供）
- [ ] `gongbei-requisition`：申购单新增/删除/更新/统计（当前仅查询）
- [ ] 各接口错误码表（业务码）与所需应用权限范围

每个接口补齐时须包含：方法（均为 POST JSON）、真实路径、请求参数表、请求/响应 JSON 示例、错误码表、所需权限。

## 3. 测试（部分完成）

- [x] 离线冒烟测试 `tests/test_gb_helper.sh`（20 项，含新缓存键与 `--categories` 资产分类静默转换）
- [x] 离线 Token 链路测试 `tests/mock_token_test.sh`（按官方响应结构 mock：appToken/expireTime，并校验请求 URL 与 Body）
- [x] ~~离线冒烟测试 `tests/test_install.sh`~~：随 `install.sh` / `install.ps1` 一并移除（安装统一使用 `npx skills add`）
- [ ] 用真实凭证跑通 `tests/test_gb_helper.sh`（Token 获取链路，需真实 appKey/appSecret）
- [ ] 按技能补集成测试（参考 dingtalk-skills 的 `tests/<skill>/` 结构，待业务接口补齐后进行）

## 4. 发布（待业务接口补齐后）

- [x] ~~一键安装脚本 `install.sh` / `install.ps1`~~：已移除，安装统一使用 `npx skills add`（见 README 快速开始）
- [ ] 更新 README / README_EN 状态列（🟡 部分就绪 → ✅ 已上线）
- [ ] 上架 ClawHub / skills.sh / Hermes
