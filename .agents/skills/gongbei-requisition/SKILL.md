---
name: gongbei-requisition
description: 公贝资产申购单只读查询。用户提到申购、申购单、资产申购、申购进度、申购记录、申购状态、申购数量、申购金额、待入库或 purchase requisition 时触发。
---

# 资产申购单

遵循 `gongbei-shared` 的 hun-cli 运行约定。本技能只做意图识别、参数提取、参数校验、选择动作和结果组织，不实现认证或 HTTP 请求。

## 能力边界

只查询资产申购单，调用时必须固定传 `formType: 40`。支持单据编码、状态、发起人/部门、关联单号、审批实例、申请时间、申购总数量、申购总金额、待入库数量和扩展字段筛选。新增、修改、删除和统计报表不在范围内。

## 调用

执行：`hun post gongbei assetOrderPage -d '<body>'`。

请求体字段、状态、比较符和返回明细见 `references/api.md`。用户按资产分类查询时使用 `extFields.text034`，资产明细从 `lists[].assetSnapshot` 读取。

## 响应组织

按用户问题提炼单据编码、状态、发起人/部门、申请时间、申购总数量/金额、待入库数量和审批实例 ID；需要明细时展开资产编码、名称、分类、位置和管理员。分页结果同时报告 `data.total`。
