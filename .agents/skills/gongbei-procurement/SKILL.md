---
name: gongbei-procurement
description: 公贝资产开放平台·采购单据（只读）。当用户提到"采购"、"采购单"、"采购单据"、"采购申请"、"采购申请单"、"采购订单"、"采购变更单"、"采购收货单"、"采购付款单"、"采购进度"、"采购记录"、"查采购"、"采购查询"、"采购状态"、"gongbei procurement"、"purchase order"、"procurement"时使用此技能。支持：采购单据分页查询（采购申请单/采购订单/采购变更单/采购收货单/采购付款单）等只读操作；不提供采购单据的写操作。
---

# 公贝资产·采购单据技能

负责公贝资产开放平台「采购单据」模块的查询。本文件为**策略指南**，仅包含决策逻辑与工作流程；完整请求格式见 `references/api.md`。

> `gb_helper.sh` 位于本 `SKILL.md` 同级目录的 `scripts/gb_helper.sh`。

## 核心概念

- **采购单据**：采购业务流转的单据，以 `formType` 区分类型并作为**必填**查询参数：`81` 采购申请单 / `82` 采购订单 / `83` 采购变更单 / `84` 采购收货单 / `85` 采购付款单。
- **单据状态（orderStatus）**：`100` 进行中 / `200` 已拒绝 / `300` 已撤销 / `400` 已完结 / `600` 待提交。
- **单据头（orderFields）**：不同单据类型字段不同；以采购申请单为例含申请人 `applyUserId/applyUserName`、申请总数量/金额 `totalApplyNum/totalApplyAmount`，以及开票/到货/入库/派发进度（`totalBilled*`、`totalArrived*`、`totalStorage*`、`totalDistributedNum`）。
- **单据明细（lists）**：每行含档案 id `archiveId`、`code/name/brand/model/unit/photos` 与申请/开票/到货/入库数量金额（`applyNum/applyAmount`、`billedNum/billedAmount`、`arrivedNum`、`storageNum` 等）。
- **只读范围**：本技能仅提供采购单据查询；新增/删除/更新采购单据及采购统计等操作不在本技能范围，请引导用户在公贝系统中处理。

## 场景路由（先分类再调 API）

| 用户意图 | 优先接口方向 |
|---|---|
| "有哪些采购申请/订单/收货单/付款单"、"查采购单"、"采购到哪一步了" | 采购单据分页查询（`formType` 必填 + filters 筛选） |
| "按单据编码/状态/发起人/关联单号查采购单" | 采购单据分页查询（通用 filters：code / orderStatus / startOrg* / startUser* / linkOrderCode / remark / processInstanceId） |
| "新增/删除/更新采购单据"、"采购统计报表" | 本技能不提供，请引导用户在公贝系统中处理 |
| 查审批状态/待办（采购单关联审批） | `gongbei-approval`（审批实例含关联单据编码 linkCode） |

## 工作流程（每次执行前）

1. **识别任务** → 按上表归类后，再选具体 API（见 `references/api.md`）。
2. **校验配置** → `bash scripts/gb_helper.sh --get GONGBEI_APP_KEY GONGBEI_APP_SECRET` 确认已配置。
3. **收集缺失项** → 若配置缺失，**一次性询问**用户并 `--set` 写入 `~/.gongbei-skills/config`。
4. **获取 Token** → `NEW_TOKEN=$(bash scripts/gb_helper.sh --token)`，业务请求以查询参数 `?appToken=${NEW_TOKEN}` 携带；遇 401 用 `--token --nocache` 强制刷新后重试。
5. **执行 API** → 多行逻辑写入 `/tmp/<task>.sh` 再执行；禁止 heredoc。
   - 查询为只读：直接调用，返回后按需提炼摘要（单据编码、类型、状态、发起人、金额/数量）。

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

# 示例：查询采购申请单（formType=81），按单据编码 + 状态筛选
curl -s -X POST "${BASE_URL}/open-api/asset-order/page?appToken=${NEW_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"current":1,"size":10,"formType":81,"filters":[{"field":"code","compare":"LK","value":"CGSQ202405140001"},{"field":"orderStatus","compare":"EQ","value":400}]}'
```

## references/api.md 查阅索引

确定好要做什么之后，用以下命令从 `references/api.md` 中提取对应章节的完整 API 细节：

```bash
grep -A 80 "^## 1. 查询采购单据" references/api.md
grep -A 15 "^## 错误码" references/api.md
grep -A 12 "^## 所需应用权限" references/api.md
```
