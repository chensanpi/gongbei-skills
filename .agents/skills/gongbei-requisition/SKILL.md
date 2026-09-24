---
name: gongbei-requisition
description: 公贝资产申购单只读查询。用户提到申购、申购单、资产申购、申购进度、申购记录、申购状态、申购数量、申购金额、待入库、申购单的关联单据或 purchase requisition 时触发。
---

# 资产申购单

遵循 `gongbei-shared` 的 hun-cli 运行约定。本技能只做意图识别、参数提取、参数校验、选择动作和结果组织，不实现认证或 HTTP 请求；所有公贝调用只能通过 `hun`，不得使用任何旁路客户端或原始 URL。

## 能力边界

- 查询资产申购单：主查询 `formType` 固定 `40`，支持单据编码、状态、发起人/部门、关联单号、审批实例、申请时间、申购总数量/总金额/待入库数量和扩展字段 `extFields` 筛选。
- 查看申购单的关联单据：读取表头 `linkOrderCode` 与单据头 `orderFields` 的关联字段，并可按关联单据编号或关联单据 ID 反查。
- 新增、修改、删除和统计报表不在范围内。

## 路由与参数

| 用户意图 | hun 调用 |
|---|---|
| 查申购单、申购进度、申购数量/金额、待入库 | `hun post gongbei assetOrderPage -d '<body>'`，`formType: 40` |
| 申购单关联了哪些单据、哪些单据关联了它 | 同一动作：先读 `linkOrderCode`/`orderFields` 关联字段，反查时传关联单据类型的 `formType` |
| 查审批进度 | `gongbei-approval`（用单据的 `processInstanceId`） |

请求体字段、状态、比较符、关联单据查找方式和返回明细见 `references/api.md`。用户按资产分类查询时使用 `extFields.text034`，资产明细从 `lists[].assetSnapshot` 读取。

只有查申购单本身时 `formType` 固定 `40`；查关联单据时按关联单据类型传 `formType`，其类型专属字段以 `gongbei-asset-order` 的 `references/api.md` 为准。

## 响应组织

按用户问题提炼单据编码、状态、发起人/部门、申请时间、申购总数量/金额、待入库数量、`linkOrderCode` 和审批实例 ID；用户问关联单据时给出关联单据编号、关联单据 ID 及反查命中的单据编码与类型；需要明细时展开资产编码、名称、分类、位置和管理员。分页结果同时报告 `data.total`。
