---
name: gongbei-approval
description: 公贝资产开放平台审批与待办查询。用户提到审批、审批实例、审批列表、审批进度、待办、我的待办、待办数量、申请单或 workflow/todo 时触发。只读。
---

# 审批与待办

遵循 `gongbei-shared` 的 hun-cli 运行约定。本技能只做意图识别、参数提取、参数校验、选择动作和结果组织，不实现认证或 HTTP 请求；所有公贝调用只能通过 `hun`，不得使用任何旁路客户端或原始 URL。

## 能力边界

- 审批实例列表：分页查询审批、状态、发起人、门店/部门、单据类型、单据编码和创建时间。
- 审批实例详情：按实例编码查询关联单据、审批摘要、评论列表、节点审批记录和当前状态。
- 用户审批待办列表：按用户查询待办，可使用 `total` 汇总待办数量。
- 已办、抄送、效率诊断，以及同意/驳回/撤销等写操作不在范围内，明确告知用户。

## 路由与参数

| 用户意图 | hun 调用 |
|---|---|
| 有哪些审批、审批进度、按条件筛审批 | `hun post gongbei processInstancePage -d '<body>'` |
| 查看某个审批实例详情、审批评论或节点记录 | `hun post gongbei processInstanceDetail -d '{"instanceCode":"实例编码"}'` |
| 我的待办、某人的待办、待办数量 | `hun post gongbei processRecordTaskPage -d '<body>'` |

请求体字段和筛选值见 `references/api.md`。按门店查询时优先生成 `filters` 中的 `startOrgName` + `lk`；不确定筛选字段时使用顶层 `keyword`。

## 复杂场景 API 调用地图

### 1. 获取指定单据的相关评论

当用户提供了单据编码，需要查询该单据对应审批流的评论时，按以下顺序调用：

1. 调用 `processInstancePage`，在 `filters` 中使用 `linkCode` 按单据编码查询审批实例列表。
2. 从返回的 `data.dataList` 中提取审批实例编码 `instanceCode`。如果存在多个审批实例，应保留各实例与其状态，逐一查询详情。
3. 对每个 `instanceCode` 调用 `processInstanceDetail`，读取详情中的 `discussList`，汇总并返回相关评论信息。

### 2. 获取指定单据及其关联单据的相关评论

#### 2.1 已知单据类型

当明确知道单据类型时，先使用对应的资产卡片分页查询获取关联单据：

1. 调用 `assetCardPage`，使用单据编码 `code` 和单据类型 `formType` 查询单据列表。
2. 从返回结果中提取关联单据编码 `linkOrderCode`。
3. 对原单据编码及所有 `linkOrderCode`，分别执行“获取指定单据的相关评论”流程：先用 `processInstancePage` 按 `linkCode` 查询(优先`compare/in`)审批实例，再用 `processInstanceDetail` 按 `instanceCode` 获取 `discussList`。

#### 2.2 未知单据类型

当只知道单据编码、不知道单据类型时，先通过审批实例列表反查单据类型：

1. 调用 `processInstancePage`，在 `filters` 中使用 `linkCode` 按单据编码查询(优先`compare/in`)审批实例列表。
2. 从返回结果中提取单据类型 `linkType`，据此确定后续应使用的单据查询方式和 `formType`。
3. 按“已知单据类型”流程调用 `assetCardPage`，查询单据及其关联单据，提取 `linkOrderCode`。
4. 对原单据和关联单据执行“获取指定单据的相关评论”流程，查询各自的审批实例详情并汇总 `discussList`。

如果任一步骤没有找到审批实例、关联单据或评论，应如实说明该单据暂无对应数据，不虚构评论；多个审批实例或关联单据的结果应标明对应的单据编码和审批实例编码。

## 响应组织

将 `data.dataList` 提炼为实例编码、标题、状态、发起人/门店、关联单据编码和时间；详情查询提炼 `discussList` 及其对应的单据编码、审批实例编码；待办额外展示 `record.userName`、`record.statusName`。同时报告分页结果的 `data.total`，不要泄露令牌或内部认证信息。
