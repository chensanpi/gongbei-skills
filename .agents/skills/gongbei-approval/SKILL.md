---
name: gongbei-approval
description: 公贝资产开放平台审批与待办查询。用户提到审批、审批实例、审批列表、审批进度、待办、我的待办、待办数量、申请单或 workflow/todo 时触发。只读。
---

# 审批与待办

遵循 `gongbei-shared` 的 hun-cli 运行约定。本技能只做意图识别、参数提取、参数校验、选择动作和结果组织，不实现认证或 HTTP 请求。

## 能力边界

- 审批实例列表：分页查询审批、状态、发起人、门店/部门、单据类型、单据编码和创建时间。
- 用户审批待办列表：按用户查询待办，可使用 `total` 汇总待办数量。
- 审批详情、已办、抄送、效率诊断，以及同意/驳回/撤销等写操作不在范围内，明确告知用户。

## 路由与参数

| 用户意图 | hun 调用 |
|---|---|
| 有哪些审批、审批进度、按条件筛审批 | `hun post gongbei processInstancePage -d '<body>'` |
| 我的待办、某人的待办、待办数量 | `hun post gongbei processRecordTaskPage -d '<body>'` |

请求体字段和筛选值见 `references/api.md`。按门店查询时优先生成 `filters` 中的 `startOrgName` + `lk`；不确定筛选字段时使用顶层 `keyword`。

## 响应组织

将 `data.dataList` 提炼为实例编码、标题、状态、发起人/门店、关联单据编码和时间；待办额外展示 `record.userName`、`record.statusName`。同时报告 `data.total`，不要泄露令牌或内部认证信息。
