# 公贝资产·审批&待办中心 API 参考

> **接口通用约定**（官方文档：https://doc.gongbeiyun.com/web/#/5/640）
> - API_HOST：`https://d-oapi.gongbeiyun.com`（统一使用；可用 `GONGBEI_BASE_URL` 覆盖）
> - 所有接口均为 **POST JSON** 请求（`Content-Type: application/json`）
> - 鉴权：`POST {API_HOST}/open-api/auth/getAppToken`，Body `{"appKey":"...","appSecret":"..."}` → 返回 `data.appToken`（有效期以 `data.expireTime` 毫秒时间戳为准）。用 `gb_helper.sh --token` 获取并缓存
> - 业务请求携带令牌：查询参数 `?appToken=<token>`
> - 统一响应结构：`{"code":"200","msg":"成功","requestId":"...","data":{...},"success":true}`；`code` 非 `"200"` 或 `success=false` 即失败，按 `msg` 提示
>
> 通用字段约定：
> - **人员字段**（`startUser`/`user`）：`field` 可选 `id`、`code`、`name`、`phone`、`email`、`thirdUserId`，`value` 为对应值
> - **部门字段**（`startOrg`）：`field` 可选 `id`、`code`、`name`、`thirdOrgId`
> - **实例状态**：`100` 进行中 / `200` 已拒绝 / `300` 已撤销 / `400` 已完结
> - **待办记录状态**：`20` 处理中
> - 时间均用**毫秒时间戳**；文档示例中的 `//` 注释实际请求时必须移除，否则 JSON 无法解析

---

## 1. 查询审批实例列表

> 分页查询审批实例列表，支持按发起人、发起部门、单据类型、单据编码、状态、创建时间筛选，返回审批摘要及关联单据信息，只读不修改。

**接口地址**：`POST {API_HOST}/open-api/system/process-instance/page?appToken=<token>`

| 参数 | 位置 | 必填 | 类型 | 说明 |
|---|---|---|---|---|
| `current` | Body | ⬜ | int | 分页值，默认 1 |
| `size` | Body | ⬜ | int | 页面大小，默认 10，最大 1000 |
| `startUser` | Body | ⬜ | object | 发起人，`{field, value}`，field 见通用约定 |
| `startOrg` | Body | ⬜ | object | 发起部门，`{field, value}` |
| `filters` | Body | ⬜ | array | 筛选条件列表，见下表 |

`filters` 支持字段：

| field | compare | value | 说明 |
|---|---|---|---|
| `linkType` | `in` | int[] | 按关联类型（单据类型）筛选，取值见下表「linkType 中文映射」 |
| `createTime` | `bt` | long[2] | 按创建时间范围筛选（毫秒时间戳，起止两值） |
| `status` | `in` | int[] | 按实例状态筛选（100/200/300/400） |
| `linkCode` | `in` | string[] | 按关联编码（单据编码）筛选 |

**linkType 中文映射**（`filters.linkType` 筛选值与响应 `dataList[].linkType` 通用）：

| linkType | linkTypeName |
|---|---|
| 8 | 资产维修单 |
| 31 | 领用 |
| 33 | 资产调拨 |
| 34 | 报修 |
| 35 | 处置 |
| 40 | 申购 |
| 111 | 耗材入库单 |
| 116 | 库存调整单 |
| 130 | 滤芯领用 |
| 132 | 耗材配件申购 |
| 135 | 门店：设计需求工单及POP物料申请 |

### 请求示例

```json
{
  "current": 1,
  "size": 10,
  "startUser": { "field": "name", "value": "张三" },
  "startOrg": { "field": "name", "value": "打杂部" },
  "filters": [
    { "field": "linkType", "compare": "in", "value": [130] },
    { "field": "createTime", "compare": "bt", "value": [1761926400000, 1764518400000] },
    { "field": "status", "compare": "in", "value": [400] },
    { "field": "linkCode", "compare": "in", "value": ["HCLY202308240001"] }
  ]
}
```

### 响应示例

```json
{
  "code": "200",
  "msg": "成功",
  "requestId": "68b0dc57-4501-4a5a-8f89-4582fc138ba1",
  "data": {
    "size": 1,
    "current": 1,
    "total": 175,
    "dataList": [
      {
        "createTime": 1692847348000,
        "instanceCode": "gb-0f59d-3fd6-4cba-a847-bce67617d830",
        "title": "库存耗材领用",
        "status": 300,
        "statusName": "已撤销",
        "contentJson": {
          "type": "kv",
          "contentText": "",
          "contentKv": [
            { "key": "单据编号", "value": "HCLY202308240001" },
            { "key": "申请人", "value": "张三" },
            { "key": "申请部门", "value": "企微测试001" }
          ]
        },
        "startUserId": "1093",
        "startUserName": "张三",
        "startUserCode": "001",
        "startOrgId": "1286",
        "startOrgName": "企微测试001",
        "startTime": 1692747360000,
        "finishTime": 1692847360000,
        "linkType": 130,
        "linkId": "1694550715499941889",
        "linkCode": "HCLY202308240001"
      }
    ]
  },
  "success": true
}
```

dataList 条目关键字段：`instanceCode` 实例编码、`title` 标题、`status`/`statusName` 状态、`contentJson.contentKv` 摘要、`startUser*`/`startOrg*` 发起人/部门、`startTime`/`finishTime`、`linkType`/`linkId`/`linkCode` 关联单据。

---

## 2. 查询用户审批待办列表

> 分页查询用户审批待办列表，返回待办实例摘要及当前节点的 record 处理记录，只读不修改。可用于查某人的待办、待办数量统计。

**接口地址**：`POST {API_HOST}/open-api/system/process-record/task/page?appToken=<token>`

| 参数 | 位置 | 必填 | 类型 | 说明 |
|---|---|---|---|---|
| `current` | Body | ⬜ | int | 分页值，默认 1 |
| `size` | Body | ⬜ | int | 页面大小，默认 10，最大 1000 |
| `user` | Body | ⬜ | object | 任务归属人，`{field, value}`；不传时查全部 |

### 请求示例

```json
{
  "current": 1,
  "size": 10,
  "user": { "field": "name", "value": "张三" }
}
```

### 响应示例

```json
{
  "code": "200",
  "msg": "成功",
  "requestId": "68b0dc57-4501-4a5a-8f89-4582fc138ba1",
  "data": {
    "size": 1,
    "current": 1,
    "total": 175,
    "dataList": [
      {
        "createTime": 1692847348000,
        "instanceCode": "gb-0f59d-3fd6-4cba-a847-bce67617d830",
        "title": "库存耗材领用",
        "status": 300,
        "statusName": "已撤销",
        "contentJson": {
          "type": "kv",
          "contentText": "",
          "contentKv": [
            { "key": "单据编号", "value": "HCLY202308240001" },
            { "key": "申请人", "value": "张三" }
          ]
        },
        "startUserName": "张三",
        "startOrgName": "企微测试001",
        "linkType": 130,
        "linkId": "1694550715499941889",
        "record": {
          "id": "1669992314325569538",
          "nodeCode": "approval-db2rmbdcosw",
          "status": 20,
          "statusName": "处理中",
          "remark": "",
          "startTime": 1686992169000,
          "userName": "王五",
          "userCode": "001"
        }
      }
    ]
  },
  "success": true
}
```

**linkType 中文映射**（响应 `dataList[].linkType`）：

| linkType | linkTypeName |
|---|---|
| 8 | 资产维修单 |
| 31 | 领用 |
| 33 | 资产调拨 |
| 34 | 报修 |
| 35 | 处置 |
| 40 | 申购 |
| 111 | 耗材入库单 |
| 116 | 库存调整单 |
| 130 | 滤芯领用 |
| 132 | 耗材配件申购 |
| 135 | 门店：设计需求工单及POP物料申请 |

> 待办列表条目的 `record.status = 20`（处理中），即当前等待该用户审批。

---

## 错误码

| 判定方式 | 说明 | 处理建议 |
|---|---|---|
| `code != "200"` 或 `success=false` | 业务失败，`msg` 为原因 | 按 `msg` 提示用户，勿重复盲目重试 |
| 业务错误码表 | 官方文档未给出具体业务码 | 常见场景按 `msg` 判断：实例不存在、权限不足等 |

Token 失效（接口返回未授权）时：`bash scripts/gb_helper.sh --token --nocache` 强制刷新后重试。

---

## 所需应用权限

> 应用需具备对应模块的接口权限（开放平台创建应用时勾选）；返回权限不足时请在开放平台为应用补授权。
