# 公贝资产·资产档案 API 参考

> **接口通用约定**（官方文档：https://doc.gongbeiyun.com/web/#/5/640）
> - API_HOST：`https://d-oapi.gongbeiyun.com`（统一使用；可用 `GONGBEI_BASE_URL` 覆盖）
> - 所有接口均为 **POST JSON** 请求（`Content-Type: application/json`）
> - 鉴权：`POST {API_HOST}/open-api/auth/getAppToken`，Body `{"appKey":"...","appSecret":"..."}` → 返回 `data.appToken`（有效期以 `data.expireTime` 毫秒时间戳为准）。用 `gb_helper.sh --token` 获取并缓存
> - 业务请求携带令牌：查询参数 `?appToken=<token>`
> - 统一响应结构：`{"code":"200","msg":"成功","requestId":"...","data":{...},"success":true}`；`code` 非 `"200"` 或 `success=false` 即失败，按 `msg` 提示
> - 表单字段结构查询：`POST {API_HOST}/open-api/system/form-config/get-field-structure?appToken=<token>`，Body `{"formType":<表单类型>}`，返回表单字段定义（含自定义字段编码）

---

## 1. 查询资产卡片（已接入）

> 资产分页查询：从公贝资产清单分页拉取资产卡片数据，支持筛选、排序，返回编码、名称、状态、分类、位置、使用人等**完整字段**。常用于发起业务单前的校验（派发时查询空闲资产、退库时查询在用资产）、资产台账查询，以及按 `updateTime` 拉取增量变更数据。

**接口地址**：`POST {API_HOST}/open-api/assets/card/page?appToken=<token>`

| 参数 | 位置 | 必填 | 类型 | 说明 |
|---|---|---|---|---|
| `current` | Body | ⬜ | int | 页面值，默认 1 |
| `size` | Body | ⬜ | int | 页面大小，默认 10，最大 1000 |
| `sorts` | Body | ⬜ | array | 排序字段集合，默认 `id desc`；元素 `{field, direction}`，`direction` 为 `asc` 正序 / `desc` 倒序 |
| `filters` | Body | ⬜ | array | 条件字段集合，元素 `{field, compare, value}`，见下方筛选字段与 compare 支持列表 |

### 常用筛选字段

| field | compare | value | 说明 |
|---|---|---|---|
| `id` | `in` | int[] | 资产 ID，值为数组 |
| `code` | `lk` | string | 资产编码模糊搜索 |
| `code.keyword` | `in` | string[] | 资产编码精确查询 |
| `name` | `lk` | string | 资产名称模糊搜索 |
| `categoryId` | `in` | int[] | 分类 ID，值为数组 |
| `categoryName` | `lk` | string | 分类名称模糊搜索 |
| `storageTime` | `bt` | long[2] | 入库时间范围查询（毫秒时间戳，起止两值） |
| `status` | `ni` | int[] | 资产状态，**默认不查询已处置状态 40**；需要同时查询已处置时可传 `ni [0]` |

> 其他字段可参照下方响应中的字段按需筛选，方式类似。

### 人员属性筛选

| field | compare | value | 说明 |
|---|---|---|---|
| `useUser.thirdUserId` | `in` | string[] | 按人员对接标识查对应**使用人**在用的资产 |
| `admin.thirdUserId` | `in` | string[] | 按人员对接标识查对应**资产管理员**管理的资产 |

> `thirdUserId` 为人员属性字段；人员可查字段还有 `name`、`code`、`phone`、`email`、`thirdUserId`。

### compare 支持列表

| compare | 描述 | 示例 |
|---|---|---|
| `eq` | 等于 | `{"field":"id","compare":"eq","value":1}` |
| `lk` | 相似（模糊） | `{"field":"name","compare":"lk","value":"张三"}` |
| `in` | 在…中 | `{"field":"id","compare":"in","value":[1,2,3]}` |
| `ni` | 不在…中 | `{"field":"id","compare":"ni","value":[1,2,3]}` |
| `bt` | 在…之间 | `{"field":"id","compare":"bt","value":[1,5]}` |
| `gt` | 大于 | `{"field":"id","compare":"gt","value":1}` |
| `lt` | 小于 | `{"field":"id","compare":"lt","value":5}` |
| `ge` | 大于等于 | `{"field":"id","compare":"ge","value":1}` |
| `le` | 小于等于 | `{"field":"id","compare":"le","value":5}` |

### 请求示例

```json
{
  "current": 1,
  "size": 10,
  "sorts": [
    { "field": "id", "direction": "desc" }
  ],
  "filters": [
    { "field": "status", "compare": "ni", "value": [40] },
    { "field": "name", "compare": "lk", "value": "笔记本" },
    { "field": "useUser.thirdUserId", "compare": "in", "value": ["022302282526519"] }
  ]
}
```

### 响应示例

```json
{
  "code": "200",
  "msg": "成功",
  "requestId": "fdaff705-af0f-4e77-8078-d32726d79821",
  "data": {
    "size": 1,
    "current": 1,
    "total": 29,
    "dataList": [
      {
        "id": 23974,
        "dataFlag": 0,
        "createTime": 1630481390000,
        "updateTime": 1630481390000,
        "corpId": 1,
        "code": "GB-00040",
        "oldCode": "",
        "codeUrl": "https://test-asset.gongbeiyun.com/a/77f5d/1/GB-00040",
        "status": 10,
        "statusName": "空闲",
        "isLock": 0,
        "lockTargetId": "",
        "lockPreStatus": -1,
        "name": "",
        "brand": "1",
        "model": "",
        "deviceSn": "",
        "categoryId": 20,
        "categoryCode": "C01",
        "categoryName": "武林八卦",
        "firstCategoryCode": "C01",
        "firstCategoryName": "武林八卦",
        "locationId": 1,
        "locationCode": "C01",
        "locationName": "北京",
        "adminId": 17,
        "adminCode": "002",
        "adminName": "李四",
        "companyId": 898,
        "companyCode": "01",
        "companyName": "北京公贝科技有限公司",
        "remark": "",
        "photos": "",
        "storageTime": 1630481390000,
        "buyDate": 1630425600000,
        "buySourceKey": "purse",
        "buySourceName": "采购",
        "orderNumber": "",
        "unit": "",
        "supplierId": 0,
        "includeTaxPrice": 12.0,
        "excludeTaxPrice": 0.0,
        "taxRate": null,
        "taxAmount": 0.0,
        "useLimit": 0,
        "maintenanceRemark": "",
        "maintenanceExpireTime": null,
        "depreciationTotal": 0.0,
        "originalValue": null,
        "depreciationResidual": 0.0,
        "depreciationClean": 0.0,
        "useUserId": 0,
        "useUserCode": "001",
        "useUserName": "张三",
        "useDepartmentId": 1,
        "useDepartmentCode": "001",
        "useDepartmentName": "北京公贝科技有限公司",
        "useStartDate": null,
        "expectReturnDate": null,
        "signatureStatus": null,
        "signatureStatusName": null,
        "signatureImg": "",
        "linkOrderNumber": "",
        "linkOrderStartTime": null,
        "supplierName": null,
        "expireTime": null,
        "freeStartDate": 1630425600000,
        "extProps": [
          { "code": "TextField_xyas01", "valueStr": "" }
        ],
        "extFields": {
          "text001": ""
        }
      }
    ]
  },
  "success": true
}
```

### 关键字段说明

| 字段 | 说明 |
|---|---|
| `code` / `oldCode` | 资产编码 / 旧资产编码 |
| `status` / `statusName` | 资产状态值 / 状态描述（如 10 空闲；已处置为 40） |
| `categoryCode` / `categoryName` | 资产分类编码 / 名称（另含一级分类 `firstCategoryCode/Name`） |
| `locationCode` / `locationName` | 存放位置编码 / 名称 |
| `adminCode` / `adminName` | 资产管理员工号 / 名称 |
| `useUserCode` / `useUserName` | 使用人工号 / 名称（另含使用部门 `useDepartmentCode/Name`） |
| `companyCode` / `companyName` | 资产所属公司编码 / 名称 |
| `storageTime` | 入库时间（毫秒时间戳） |
| `buyDate` / `buySourceName` | 购置时间 / 购置方式名称 |
| `includeTaxPrice` / `excludeTaxPrice` | 含税金额 / 不含税金额 |
| `updateTime` | 最后更新时间，**可按此字段查询增量变更数据** |
| `extProps` / `extFields` | 自定义字段值集合（字段名需查模板字段定义，可调用表单字段结构接口 get-field-structure 查询） |

---

## 2. 查询资产操作记录（已接入）

> 分页获取资产操作记录（操作履历）：入库、借出、派发、调拨等每次变更的操作人、操作类型、变更内容及关联单据号，用于追溯变更历史、排查问题，只读不修改；也可对接外部系统做变更同步。

**接口地址**：`POST {API_HOST}/open-api/assets/asset-operate-log/page?appToken=<token>`

| 参数 | 位置 | 必填 | 类型 | 说明 |
|---|---|---|---|---|
| `current` | Body | ⬜ | int | 页面值，默认 1 |
| `size` | Body | ⬜ | int | 页面大小，默认 10，最大 1000 |
| `sorts` | Body | ⬜ | array | 排序字段集合，默认 `id desc`；元素 `{field, direction}` |
| `filters` | Body | ⬜ | array | 条件字段集合，元素 `{field, compare, value}`，compare 支持列表见第 1 节 |

### 常用筛选字段

| field | compare | value | 说明 |
|---|---|---|---|
| `assetCardId` | `in` | int[] | 资产 ID，值为数组 |
| `operationType` | `eq` | int | 操作类型 |
| `operatorId` | `eq` | int | 操作人 ID |
| `createTime` | `bt` | long[2] | 操作时间范围查询（毫秒时间戳，起止两值） |

> 其他字段可参照下方响应中的字段按需筛选，方式类似。

### 请求示例

```json
{
  "current": 1,
  "size": 10,
  "sorts": [
    { "field": "id", "direction": "desc" }
  ],
  "filters": [
    { "field": "assetCardId", "compare": "in", "value": [23974] }
  ]
}
```

### 响应示例

```json
{
  "code": "200",
  "msg": "成功",
  "requestId": "5c427990-4b7d-4ea7-9ef1-b481e178e2f6",
  "data": {
    "size": "10",
    "current": "1",
    "total": "57",
    "dataList": [
      {
        "id": "38208",
        "dataFlag": 0,
        "createTime": 1633942186000,
        "updateTime": 1633942186000,
        "assetCardId": "24416",
        "operatorId": "1100",
        "operatorName": "贾朦",
        "operationType": 10,
        "operationTypeName": "资产入库",
        "operationContent": "单据编号：ZCRK202110110002,资产状态由\"\"变更为\"空闲\",资产分类由\"\"变更为\"笔记本电脑\",所在位置由\"\"变更为\"北京\",管理员由\"\"变更为\"贾朦\",所属公司由\"\"变更为\"玛卡巴卡科技有限公司\",购置方式由\"\"变更为\"采购\",使用部门由\"\"变更为\"自建01\",资产编码由\"\"变更为\"GB-00046\",品牌由\"\"变更为\"123\",入库时间由\"\"变更为\"2021-10-11\",购置时间由\"\"变更为\"2021-10-11\",购置金额（含税）由\"\"变更为\"1231231.111\",数字输入框由\"\"变更为\"123123.111\"",
        "signImg": "",
        "operationRemark": "",
        "relatedTargetId": "ZCRK202110110002"
      }
    ]
  },
  "success": true
}
```

### 关键字段说明

| 字段 | 说明 |
|---|---|
| `assetCardId` | 资产 ID |
| `createTime` | 操作时间（毫秒时间戳） |
| `operatorId` / `operatorName` | 操作人 ID / 名称 |
| `operationType` / `operationTypeName` | 操作类型 / 名称（如 10 资产入库） |
| `operationContent` | 变更内容明细（各字段由旧值变更为新值） |
| `relatedTargetId` | 关联单据编号 |

---

## 3. 查询资产状态列表（已接入）

> 返回公贝系统中所有资产状态的枚举值，可用作查询资产状态的筛选、判断业务逻辑等用途。

**接口地址**：`POST {API_HOST}/open-api/assets/card/status/list?appToken=<token>`

### 请求示例

```json
{}
```

### 响应示例

```json
{
  "code": "200",
  "msg": "成功",
  "requestId": "9966c737-2d0b-4990-9eaf-812a9cf99c97",
  "data": [
    { "code": 10, "desc": "空闲" },
    { "code": 20, "desc": "在用" },
    { "code": 30, "desc": "借用" },
    { "code": 40, "desc": "已处置" },
    { "code": 50, "desc": "已报失" },
    { "code": 100, "desc": "派发中" },
    { "code": 110, "desc": "退库中" },
    { "code": 120, "desc": "借出中" },
    { "code": 130, "desc": "归还中" },
    { "code": 140, "desc": "维修中" },
    { "code": 150, "desc": "处置中" },
    { "code": 160, "desc": "调拨中" },
    { "code": 170, "desc": "批量修改中" },
    { "code": 180, "desc": "领用人变更中" },
    { "code": 190, "desc": "领用申请中" },
    { "code": 200, "desc": "借用申请中" },
    { "code": 210, "desc": "退还中" },
    { "code": 220, "desc": "交接中" },
    { "code": 230, "desc": "报修中" },
    { "code": 240, "desc": "报失中" },
    { "code": 250, "desc": "补充中" },
    { "code": 260, "desc": "待处置" },
    { "code": 270, "desc": "故障" },
    { "code": 280, "desc": "校验中" },
    { "code": 290, "desc": "保养中" },
    { "code": 300, "desc": "主附调整中" },
    { "code": 310, "desc": "盘亏中" },
    { "code": 320, "desc": "共享申请中" },
    { "code": 330, "desc": "更换中" }
  ],
  "success": true
}
```

> 第 1 节「查询资产卡片」中 `status` 筛选的枚举值取自本接口；已处置为 40。

---

## 错误码

| 判定方式 | 说明 | 处理建议 |
|---|---|---|
| `code != "200"` 或 `success=false` | 业务失败，`msg` 为原因 | 按 `msg` 提示用户，勿重复盲目重试 |
| 业务错误码表 | 官方文档未公开具体码表 | 以响应 msg 为准判断原因并提示用户 |

Token 失效（接口返回未授权）时：`bash scripts/gb_helper.sh --token --nocache` 强制刷新后重试。

---

## 所需应用权限

> 应用需具备对应模块的接口权限（开放平台创建应用时勾选）；返回权限不足时请在开放平台为应用补授权。
