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
- **只读范围**：本技能仅提供资产申购单查询；新增/删除/更新申购单及申购统计等操作不在本技能范围，请引导用户在公贝系统中处理。

## 场景路由（先分类再调 API）

| 用户意图 | 优先接口方向 |
|---|---|
| "有哪些申购单"、"查申购单"、"申购到哪一步了" | 资产申购单分页查询（`formType=40` + filters 筛选） |
| "按单据编码/状态/发起人/关联单号查申购单" | 资产申购单分页查询（通用 filters：code / orderStatus / startOrg* / startUser* / linkOrderCode / remark / processInstanceId） |
| "按申请时间/申购总数量/申购总金额/待入库数量筛申购单" | 资产申购单分页查询（申购单专属 filters：orderFields.operateTime / purchaseSumCount / purchaseSumAmount / waitStorageSumCount） |
| "查申购单里的资产明细/分类/位置/管理员" | 资产申购单分页查询（明细 filters：lists.assetSnapshot.*，如 categoryName / locationName / adminName / brand / model / deviceSn） |
| "新增/删除/更新申购单"、"申购统计报表" | 本技能不提供，请引导用户在公贝系统中处理 |
| 其它单据类型（formType 81-85 等，属 `gongbei-procurement` 范围） | `gongbei-procurement` |
| 查审批状态/待办（申购单关联审批） | `gongbei-approval`（审批实例含关联单据编码 linkCode） |

## 工作流程（每次执行前）

1. **识别任务** → 按上表归类后，再选具体 API（见 `references/api.md`）。
2. **校验配置** → `bash scripts/gb_helper.sh --get GONGBEI_APP_KEY GONGBEI_APP_SECRET` 确认已配置。
3. **收集缺失项** → 若配置缺失，**一次性询问**用户并 `--set` 写入 `~/.gongbei-skills/config`。
4. **获取 Token** → `NEW_TOKEN=$(bash scripts/gb_helper.sh --token)`，业务请求以查询参数 `?appToken=${NEW_TOKEN}` 携带；遇 401 用 `--token --nocache` 强制刷新后重试。
5. **执行 API** → 多行逻辑写入 `/tmp/<task>.sh` 再执行；禁止 heredoc。
   - 查询为只读：直接调用，返回后按需提炼摘要（单据编码、状态、发起人/部门、申购总数量/金额、待入库数量）。

> 凭证禁止完整打印，确认时仅显示前 4 位 + `****`。未通过配置校验前不得调用 API。

### 所需配置

| 配置键 | 必填 | 说明 |
|---|---|---|
| `GONGBEI_APP_KEY` | ✅ | 开放平台应用 AppKey |
| `GONGBEI_APP_SECRET` | ✅ | 开放平台应用 AppSecret |
| `GONGBEI_BASE_URL` | ⬜ | API_HOST 覆盖（默认 `https://d-oapi.gongbeiyun.com`） |

### 执行脚本模板

```bash
#!/bin/bash
set -e
HELPER="./scripts/gb_helper.sh"
NEW_TOKEN=$(bash "$HELPER" --token)
BASE_URL="${GONGBEI_BASE_URL:-https://d-oapi.gongbeiyun.com}"

# 示例：查询资产申购单（formType=40），按单据编码 + 状态筛选
curl -s -X POST "${BASE_URL}/open-api/asset-order/page?appToken=${NEW_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"size":10,"current":1,"formType":40,"filters":[{"field":"code","compare":"LK","value":"ZCRK202209160001"},{"field":"orderStatus","compare":"EQ","value":400}]}'
```

## references/api.md 查阅索引

确定好要做什么之后，用以下命令从 `references/api.md` 中提取对应章节的完整 API 细节：

```bash
grep -A 100 "^## 1. 查询资产申购单" references/api.md
grep -A 15 "^## 错误码" references/api.md
grep -A 12 "^## 所需应用权限" references/api.md
```
