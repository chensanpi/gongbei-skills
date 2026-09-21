# 审批与待办 API 参考

认证、网关地址和请求头由 `gongbei-shared` 与 hun-cli 处理。每个动作的 HTTP 方法、请求体和字段以本文件为准。当前三个动作均为：`hun post gongbei <action> -d '<JSON>'`。

## 统一响应

公贝业务响应统一为：

```json
{
  "rtn": "success",
  "errCode": "200_E_OK",
  "errMsg": "操作成功",
  "data": {},
  "success": true
}
```

`success=true` 表示成功；成功数据在 `data`，失败原因在 `errMsg`。`data` 为分页对象时，列表在 `data.dataList`，总数在 `data.total`。

## 通用参数与映射

- 所有查询字段均可选；未传分页时使用服务端默认值。
- `current`：页码，默认 1；`size`：每页数量，默认 10，最大 1000。
- `keyword`：顶层兜底模糊检索字段，与 `current`/`size` 同级；没有合适的专用字段时使用。
- 人员对象 `startUser`/`user`：`{field,value}`，`field` 支持 `id`、`code`、`name`、`phone`、`email`、`thirdUserId`。
- 部门对象 `startOrg`：`{field,value}`，`field` 支持 `id`、`code`、`name`、`thirdOrgId`。
- 时间字段均为 Unix 毫秒时间戳。
- `filters` 元素为 `{field,compare,value}`。比较符：`lk` 模糊、`in` 包含、`bt` 区间。

实例状态：`100` 进行中、`200` 已拒绝、`300` 已撤销、`400` 已完结。待办记录状态：`20` 处理中。

`linkType` 映射：`8` 资产维修单、`31` 领用、`33` 资产调拨、`34` 报修、`35` 处置、`40` 申购、`111` 耗材入库单、`116` 库存调整单、`130` 滤芯领用、`132` 耗材配件申购、`135` 门店设计需求工单及 POP 物料申请。

按单门店查询时优先使用：`{"field":"startOrgName","compare":"lk","value":"门店名"}`。
按多门店查询时优先使用：`{"field":"startOrgName","compare":"in","value":["门店名1","门店名2"]}`。


## 1. 审批实例列表

动作：`processInstancePage`

用途：查询审批实例、审批进度和关联单据；只读。

请求体字段：

| 字段 | 类型 | 说明 |
|---|---|---|
| `current` / `size` | int | 分页 |
| `keyword` | string | 兜底模糊查询 |
| `startUser` | object | 发起人，`{field,value}` |
| `startOrg` | object | 发起部门，`{field,value}` |
| `filters` | array | 支持 `linkType` 单据类型、`createTime`、`status`、`linkCode`等，也可按响应字段筛选 |

示例：

```json
{
  "current": 1,
  "size": 10,
  "filters": [
    {"field": "status", "compare": "in", "value": [100, 400]},
    {"field": "startOrgName", "compare": "lk", "value": "测试门店"}
  ]
}
```

关键筛选/响应字段：`statusName` 状态名；`startUserId`、`startUserName`、`startUserCode`、`startThirdUserId`、`startThirdUnionId` 发起人；`startOrgId`、`startOrgName` 发起门店/部门；`createTime`、`startTime`、`finishTime` 时间；`efficiencyDuration` 秒、`efficiencyDurationHour` 小时；`linkType`、`linkId`、`linkCode` 关联单据。

列表条目还包括：`instanceCode` 实例编码、`title` 标题、`status`/`statusName` 状态、`contentJson` 审批摘要。`contentJson.type=kv` 时，从 `contentJson.contentKv[]` 读取 `{key,value}` 摘要，例如单据编号、申请人、申请部门。

## 2. 用户审批待办列表

动作：`processRecordTaskPage`

用途：查询某用户或当前授权范围内的审批待办，并用 `data.total` 统计数量；只读。

请求体字段：

| 字段 | 类型 | 说明 |
|---|---|---|
| `current` / `size` | int | 分页 |
| `keyword` | string | 兜底模糊查询 |
| `user` | object | 任务归属人，`{field,value}`；不传时按接口默认范围查询 |
| `filters` | array | 可使用 `startOrgName` 等实例字段筛选 |

示例：

```json
{
  "current": 1,
  "size": 10,
  "user": {"field": "name", "value": "王五"},
  "filters": [{"field": "startOrgName", "compare": "lk", "value": "测试门店"}]
}
```

列表条目复用审批实例字段，并增加 `record`：`record.id`、`nodeCode`、`status`/`statusName`、`remark`、`startTime`、`userName`、`userCode`。待办处理中的记录通常为 `record.status=20`。

## 3. 审批实例详情

动作：`processInstanceDetail`

用途：按审批实例编码查询单条审批流的完整详情，包括关联单据、审批摘要、评论列表、各节点审批记录及当前状态；只读。

请求体字段：

| 字段 | 类型 | 必选 | 说明 |
|---|---|---|---|
| `instanceCode` | string | 是 | 审批实例编码 |

示例：

```json
{
  "instanceCode": "gb-0aee7-ba2a-4e0d-ba00-7043df956885"
}
```

响应 `data` 为审批实例详情对象，主要字段：

- 实例信息：`instanceCode`、`title`、`status`/`statusName`、`createTime`、`updateTime`、`finishTime`。
- 发起与关联单据：`startUserId`、`startUserName`、`startUserCode`、`startOrgId`、`startOrgName`、`linkType`、`linkId`、`linkCode`。
- 审批摘要：`contentJson.type`、`contentJson.contentText`、`contentJson.contentKv[]`，其中每项为 `{key,value}`。
- 审批评论：`discussList` 评论列表；有评论时原样保留评论对象及其字段，不将空数组误报为有评论。评论中存在图片链接（photoUrls）时，需要原样展示给用户。
- 节点记录：`nodes[]` 的 `code`、`name`、`nodeType` 和 `records[]`；记录包含 `userName`、`status`/`statusName`、`remark`、`startTime`、`finishTime` 等字段。

调用时从用户请求中提取实例编码；缺少实例编码时先向用户索取，不发送空请求体。

## 响应组织

审批实例提炼 `instanceCode`、`title`、`statusName`、发起人/门店、`contentJson.contentKv`、`linkCode` 和时间；详情额外展示 `discussList` 评论和按节点归组的审批记录；待办额外提炼当前节点处理人和 `record.statusName`。分页结果始终报告 `data.total`，详情结果不虚构分页总数；失败时使用 `errMsg`，不要展示认证材料。
