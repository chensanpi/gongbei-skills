---
name: gongbei-asset-order
description: 公贝资产单据通用只读查询。用户提到资产单据、单据查询、单据编码、单据状态、入库单、借用单、归还单、派发单、退库单、调拨单、维修单、处置单、批量修改单、领用申请单、资产报修单、资产退还单、关联单据编号或 asset order 时触发。
---

# 资产单据（通用）

遵循 `gongbei-shared` 的 hun-cli 运行约定。本技能只做意图识别、参数提取、参数校验、选择动作和结果组织，不实现认证或 HTTP 请求；所有公贝调用只能通过 `hun`，不得使用任何旁路客户端或原始 URL。

## 能力边界

- 分页查询资产单据：一次只查一类单据，用 `formType` 指定。
- 已覆盖 formType：2 入库单、3 借用单、4 归还单、5 派发单、6 退库单、7 调拨单、8 维修单、9 处置单、10 批量修改单、31 领用申请单、34 资产报修单、36 资产退还单。
- 查看关联单据编号：读取单据的 `linkOrderCode` 与 `orderFields` 关联字段，并可用 `linkOrderCode` 反查关联单据。
- 单据的新增、修改、删除、审批及导出不在范围内；审批进度用 `gongbei-approval`。

## 路由与参数

| 用户意图 | hun 调用 |
|---|---|
| 查某类资产单据、单据列表、按单据编码/状态筛单据 | `hun post gongbei assetOrderPage -d '<body>'` |
| 查关联单据编号、这单关联了哪些单、哪些单关联了它 | 同一动作，读 `linkOrderCode` 或加 `linkOrderCode` 过滤 |

`formType` 必填且一次只能传一个，取值以 `references/api.md` 的 formType 速查表为准：先从用户语句映射单据类型；用户未说明且无法从上下文推断时，列出速查表中的类型请其确认，不要遍历 `formType` 试探。

请求体字段、各类型的 `filters` 字段和比较符见 `references/api.md`；不同单据类型的筛选字段不同，只使用该 `formType` 名下的字段，不要跨类型拼接或臆造字段。

## 关联单据编号

- 先读表头 `linkOrderCode`；为空表示该单据没有关联单据，如实说明，不要推断或虚构。
- 再看 `orderFields` 中的关联字段：入库单的 `relatedOrderId`（关联单据 ID）、派发单的 `receiveCode`/`receiveId`（领用申请单单号/ID）等属于单据头信息。
- 需要查"它关联了谁"或"谁关联了它"时，用 `filters` 的 `linkOrderCode` 配合 `EQ`/`LK` 在目标单据类型下查询；跨类型时逐类查询，接口未提供按单据 ID 过滤的字段，不要臆造。

## 响应组织

按用户问题提炼单据编码、单据类型、状态、发起人/部门、创建时间、备注、审批实例 ID 和关联单据编号；需要明细时展开 `lists[].assetSnapshot` 的资产编码、名称、分类、位置、管理员和公司。分页结果同时报告 `data.total`。
