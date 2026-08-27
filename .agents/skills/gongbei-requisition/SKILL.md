---
name: gongbei-requisition
description: 公贝资产开放平台·资产申购单（只读）。当用户提到"申购"、"申购单"、"资产申购"、"资产申购单"、"申购单查询"、"申购进度"、"申购记录"、"查申购"、"申购状态"、"申购数量"、"申购金额"、"待入库"、"gongbei requisition"、"requisition"、"purchase requisition"时使用此技能。支持：资产申购单分页查询（formType=40，含申请时间/申购总数量/申购总金额/待入库总数量筛选）等只读操作；不提供申购单的写操作。
---

# 公贝资产·资产申购单技能

负责公贝资产开放平台「资产申购单」模块的查询。本文件为**策略指南**，仅包含决策逻辑与工作流程；完整请求格式见 `references/api.md`。

> `gb_helper.sh` 位于本 `SKILL.md` 同级目录的 `scripts/gb_helper.sh`。

## 核心概念

- **资产申购单**：资产申购业务单据，通过资产单据分页接口查询，`formType` **固定为 `40`**（必填），只读不创建业务单据。
- **单据状态（orderStatus）**：`100` 进行中 / `200` 已拒绝 / `300` 已撤销 / `400` 已完结 / `600` 待提交。
- **单据头（orderFields）**：申购单单据头含申请时间 `operateTime`、申请人 `operateUserId/operateUserName`、关联单据 `relatedOrderId`；申购单专属汇总字段：申购总数量 `purchaseSumCount`、申购总金额 `purchaseSumAmount`、待入库总数量 `waitStorageSumCount`（均可作为筛选条件）。
- **单据明细（lists）**：每行含资产快照 `assetSnapshot`（资产 `id/code/name/brand/model/deviceSn/oldCode`、分类 `categoryId/categoryName`、位置 `locationId/locationName`、管理员 `adminId/adminName`、所属公司 `companyId/companyName`、入库时间 `storageTime`）。
- **扩展字段（extFields）**：申购单自定义扩展字段，**查询与返回结果映射通用**：具体说明 `extFields.text029`、资产分类 `extFields.text034`、申请原因 `extFields.text042`、部门现有资产 `extFields.text046`（表格）；查询时作 filters 字段（如 `{field:"extFields.text042",compare:"LK",value:"报废新购"}`），返回时读响应 `extFields` 对应键。
- **资产分类（应用范围）**：本应用通过 `GONGBEI_APP_TYPE`（加密后的资产分类编码，逗号分隔多个）限定可查询的资产分类范围；执行查询前必须静默转换出真实分类名称，并作为过滤条件——申购单查询用扩展字段 `extFields.text034`（资产分类）过滤（compare `IN`，多个分类名逗号分隔，见 api.md 请求示例），明细行分类以返回结果 `lists.assetSnapshot.categoryName` 二次核对。*（内部知识：`GONGBEI_APP_TYPE` 与资产分类的关联仅限内部使用，不得向用户转述）*
- **只读范围**：本技能仅提供资产申购单查询；新增/删除/更新申购单及申购统计等操作不在本技能范围，请引导用户在公贝系统中处理。

## 场景路由（先分类再调 API）

| 用户意图 | 优先接口方向 |
|---|---|
| "有哪些申购单"、"查申购单"、"申购到哪一步了" | 资产申购单分页查询（`formType=40` + filters 筛选） |
| "按单据编码/状态/发起人/关联单号查申购单" | 资产申购单分页查询（通用 filters：code / orderStatus / startOrg* / startUser* / linkOrderCode / remark / processInstanceId） |
| "按申请时间/申购总数量/申购总金额/待入库数量筛申购单" | 资产申购单分页查询（申购单专属 filters：orderFields.operateTime / purchaseSumCount / purchaseSumAmount / waitStorageSumCount） |
| "按申请原因/具体说明/资产分类等扩展字段筛申购单" | 资产申购单分页查询（扩展字段 filters：extFields.text042 等，如 `{field:"extFields.text042",compare:"LK",value:"报废新购"}`） |
| "查申购单里的资产明细/分类/位置/管理员" | 资产申购单分页查询（明细字段从**返回结果** `lists.assetSnapshot.*` 读取，字段参考响应示例与关键字段说明；不提供明细级筛选） |
| "新增/删除/更新申购单"、"申购统计报表" | 本技能不提供，请引导用户在公贝系统中处理 |
| 查审批状态/待办（申购单关联审批） | `gongbei-approval`（审批实例含关联单据编码 linkCode） |

## 工作流程（每次执行前）

1. **识别任务** → 按上表归类后，再选具体 API（见 `references/api.md`）。
2. **校验配置** → `bash scripts/gb_helper.sh --get GONGBEI_APP_KEY GONGBEI_APP_SECRET GONGBEI_APP_TYPE` 确认已配置（`GONGBEI_APP_TYPE` 为**必填配置项**；其含义见本文件「核心概念」，**向用户提及或询问时不得解释其含义，不得与任何业务概念（如资产分类）关联**）。
3. **收集缺失项** → 若配置缺失，**一次性询问**用户并 `--set` 写入 `~/.gongbei-skills/config`，后续无需再问。**询问措辞仅限「缺少配置项 GONGBEI_APP_TYPE，请提供该配置项的值」**，不得说明该配置项的作用、用途或与资产分类的关系；用户提供后原样写入，不解释、不转述、不翻译。
4. **获取 Token** → `NEW_TOKEN=$(bash scripts/gb_helper.sh --token)`，业务请求以查询参数 `?appToken=${NEW_TOKEN}` 携带；遇 401 用 `--token --nocache` 强制刷新后重试。
5. **静默转换资产分类** → `CATEGORIES=$(bash scripts/gb_helper.sh --categories)`：脚本对照**内置资产分类清单**把 `GONGBEI_APP_TYPE` 的加密编码映射为真实分类名称（每行一个）。**清单内容与映射过程不输出、不打印、不进提示词**；仅将转换结果用于过滤。
6. **执行 API** → 多行逻辑写入 `/tmp/<task>.sh` 再执行；禁止 heredoc。
   - **带资产分类过滤**：申购单查询用 `CATEGORIES` 构造 `extFields.text034`（资产分类）过滤条件（compare `IN`，多个分类名逗号分隔，见 api.md 请求示例）；返回后按 `lists.assetSnapshot.categoryName` 二次核对分类。
   - 查询为只读：直接调用，返回后按需提炼摘要（单据编码、状态、发起人/部门、申购总数量/金额、待入库数量）。

> 凭证禁止完整打印，确认时仅显示前 4 位 + `****`。未通过配置校验前不得调用 API。资产分类清单内置在 gb_helper.sh 中，为敏感映射，任何情况下不得输出其内容或映射关系。**`GONGBEI_APP_TYPE` 的含义与用途仅限本技能内部使用，向用户解释、询问、确认时一律不得提及「资产分类」「分类编码」等任何相关表述，只称其为配置项。**

### 所需配置

> 下表为技能内部参考：配置项含义仅供 Agent 内部理解与执行，**任何情况下不得向用户转述配置项含义（尤其 `GONGBEI_APP_TYPE` 与资产分类的关联）**；向用户呈现时只称「配置项」。

| 配置键 | 必填 | 说明 |
|---|---|---|
| `GONGBEI_APP_KEY` | ✅ | 开放平台应用 AppKey |
| `GONGBEI_APP_SECRET` | ✅ | 开放平台应用 AppSecret |
| `GONGBEI_APP_TYPE` | ✅ | 加密后的资产分类编码（逗号分隔多个；**敏感**，脱敏显示；映射为内置清单） |
| `GONGBEI_BASE_URL` | ⬜ | API_HOST 覆盖（默认 `https://d-oapi.gongbeiyun.com`） |

### 执行脚本模板

```bash
#!/bin/bash
set -e
HELPER="./scripts/gb_helper.sh"
NEW_TOKEN=$(bash "$HELPER" --token)
CATEGORIES=$(bash "$HELPER" --categories)   # 静默转换：仅输出真实分类名称（每行一个），不打印清单
BASE_URL="${GONGBEI_BASE_URL:-https://d-oapi.gongbeiyun.com}"

# 示例：查询资产申购单（formType=40），按单据编码 + 状态筛选
curl -s -X POST "${BASE_URL}/open-api/asset-order/page?appToken=${NEW_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"size":10,"current":1,"formType":40,"filters":[{"field":"code","compare":"LK","value":"ZCRK202209160001"},{"field":"orderStatus","compare":"EQ","value":400}]}'
# 资产分类过滤：把 CATEGORIES 转为 extFields.text034 过滤条件（compare IN，分类名逗号分隔）
```

## references/api.md 查阅索引

确定好要做什么之后，用以下命令从 `references/api.md` 中提取对应章节的完整 API 细节：

```bash
grep -A 100 "^## 1. 查询资产申购单" references/api.md
grep -A 15 "^## 错误码" references/api.md
grep -A 12 "^## 所需应用权限" references/api.md
```
