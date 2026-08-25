# 公贝资产·采购单据 API 参考

> **接口通用约定**（官方文档：https://doc.gongbeiyun.com/web/#/5/640）
> - API_HOST：`https://d-oapi.gongbeiyun.com`（统一使用；可用 `GONGBEI_BASE_URL` 覆盖）
> - 所有接口均为 **POST JSON** 请求（`Content-Type: application/json`）
> - 鉴权：`POST {API_HOST}/open-api/auth/getAppToken`，Body `{"appKey":"...","appSecret":"..."}` → 返回 `data.appToken`（有效期以 `data.expireTime` 毫秒时间戳为准）。用 `gb_helper.sh --token` 获取并缓存
> - 业务请求携带令牌：查询参数 `?appToken=<token>`
> - 统一响应结构：`{"code":"200","msg":"成功","requestId":"...","data":{...},"success":true}`；`code` 非 `"200"` 或 `success=false` 即失败，按 `msg` 提示
> - 时间均用**毫秒时间戳**；文档示例中的 `//` 注释实际请求时必须移除，否则 JSON 无法解析

---

## 1. 查询采购单据（已接入）

> 分页查询资产单据（同一接口 `asset-order/page` 亦支持其它资产单据类型，本技能聚焦采购单据）。按 `formType` 指定单据类型**只读**查询，不创建业务单据；对接外部系统时可同步业务单据。

**接口地址**：`POST {API_HOST}/open-api/asset-order/page?appToken=<token>`

| 参数 | 位置 | 必填 | 类型 | 说明 |
|---|---|---|---|---|
| `current` | Body | ⬜ | int | 当前页码，默认 1 |
| `size` | Body | ⬜ | int | 每页条数，默认 10，最大 1000 |
| `keyword` | Body | ⬜ | string | 模糊查询关键字 |
| `formType` | Body | ✅ | int | 单据类型（必填），见下方采购表单类型 |
| `filters` | Body | ⬜ | array | 条件字段集合，元素 `{field, compare, value}`，见下方通用筛选字段与 compare 比较符 |

### 采购表单类型（formType）

| formType | 单据名称 |
|---|---|
| 81 | 采购申请单 |
| 82 | 采购订单 |
| 83 | 采购变更单 |
| 84 | 采购收货单 |
| 85 | 采购付款单 |

### 单据通用 filters 查询字段

| field | 类型 | value 示例 | 说明 |
|---|---|---|---|
| `code` | String | CGSQ202405140001 | 单据编码 |
| `orderStatus` | int | 400 | 单据状态：100 进行中 / 200 已拒绝 / 300 已撤销 / 400 已完结 / 600 待提交 |
| `startOrgId` | long | 1652829933 | 发起人组织 id（参照：员工分页查询、部门分页查询） |
| `startOrgName` | String | 研发部 | 发起人组织名称 |
| `startUserId` | long | 123423422 | 发起人员 id |
| `startUserName` | String | 张三 | 发起人员名称 |
| `linkOrderCode` | String | CGSQ202405140001 | 关联单据编号 |
| `remark` | String | 测试 | 备注 |
| `processInstanceId` | String | GB-10003-2003333 | 审批实例 ID |

### compare 比较符

| 比较符 | 说明 | 支持类型 |
|---|---|---|
| `EQ` | 等于 | 字符, 数值, 日期 |
| `LT` | 小于 | 数值, 日期 |
| `GT` | 大于 | 数值, 日期 |
| `LE` | 小于等于 | 数值, 日期 |
| `GE` | 大于等于 | 数值, 日期 |
| `NE` | 不等于 | 字符, 数值, 日期 |
| `LK` | 相似（模糊检索） | 字符 |
| `NLK` | 不相似 | 字符 |
| `LFK` | 左相似 | 字符 |
| `RHK` | 右相似 | 字符 |
| `INL` | 为空 | 字符, 数值, 日期 |
| `NNL` | 非空 | 字符, 数值, 日期 |
| `IN` | 批量查询（精确批量查询） | 字符, 数值, 日期 |
| `NI` | 不在其中 | 字符, 数值, 日期 |
| `BT` | 区间范围 | 数值, 日期 |

### 请求示例

```json
{
  "size": 10,
  "current": 1,
  "keyword": "",
  "formType": 81,
  "filters": [
    { "field": "code", "compare": "LK", "value": "CGSQ202405140001" },
    { "field": "orderStatus", "compare": "EQ", "value": 400 }
  ]
}
```

### 响应示例（采购申请单 formType=81）

```json
{
  "code": "200",
  "msg": "成功",
  "requestId": "250528171617676544",
  "data": {
    "size": 10,
    "current": 1,
    "total": 1,
    "dataList": [
      {
        "id": "1925477008998277121",
        "dataFlag": 0,
        "createTime": 1747904466000,
        "updateTime": 1748420580000,
        "corpId": "104",
        "name": "采购申请",
        "code": "CGSQ202505220001",
        "formType": 81,
        "formConfigId": "1921032531890016257",
        "processType": 0,
        "orderStatus": 400,
        "orderStatusName": "已完结",
        "startOrgId": "0",
        "startOrgName": "",
        "startUserId": "0",
        "startUserName": "system",
        "startTime": 1747904467000,
        "finishTime": 1747904469000,
        "sourceOrderCode": "",
        "linkOrderCode": "",
        "extFields": {},
        "remark": "测试api",
        "processInstanceId": "gb-3188c-8b54-4f08-a99c-517fd7a30e54",
        "dingInstanceUrl": "",
        "detailUrl": "https://test-asset.gongbeiyun.com/gb/h5/buy?ddtab=true&sourceType=2&uuid=44f9303f-c783-4180-b602-b36dc853bc301925477008998277121&cropId=104&formType=81",
        "orderFields": {
          "applyUserId": "1150",
          "applyUserName": "自建人2",
          "operateTime": 1747904466561,
          "totalApplyNum": 3.0,
          "totalApplyAmount": 6.0,
          "totalBilledNum": 3.0,
          "totalUnBilledNum": 0.0,
          "totalBilledRate": 100.0,
          "totalBilledAmount": 6.0,
          "totalArrivedNum": 3.0,
          "totalUnArrivedNum": 0.0,
          "totalArrivedRate": 100.0,
          "totalStorageNum": 0.0,
          "totalUnStorageNum": 3.0,
          "totalStorageRate": 0.0,
          "totalDistributedNum": 0.0
        },
        "lists": [
          {
            "id": "1925477009547730945",
            "orderId": "1925477008998277121",
            "extFields": {},
            "orderFields": {
              "detailType": 2,
              "categoryName": "",
              "archiveId": "532",
              "code": "123",
              "name": "一次性杯子",
              "brand": "1213456",
              "model": "24354",
              "unit": "个",
              "photos": "https://a-oss.gongbeiyun.com/file/104/202109/1631104773515.png",
              "applyPrice": 0.0,
              "applyNum": 3.0,
              "applyAmount": 6.0,
              "unBilledNum": 0.0,
              "billedNum": 3.0,
              "billedAmount": 6.0,
              "unArrivedNum": 0.0,
              "arrivedNum": 3.0,
              "storageNum": 0.0,
              "unStorageNum": 3.0,
              "distributedNum": 0.0
            }
          }
        ]
      }
    ]
  },
  "success": true
}
```

### 关键字段说明

| 字段 | 说明 |
|---|---|
| `code` / `name` | 单据编码 / 单据类型名称 |
| `formType` | 单据类型（81-85） |
| `orderStatus` / `orderStatusName` | 单据状态 / 描述（100 进行中 / 200 已拒绝 / 300 已撤销 / 400 已完结 / 600 待提交） |
| `startOrgId/Name`、`startUserId/Name` | 发起部门 / 发起人 |
| `processInstanceId` | 审批实例 ID（可关联 `gongbei-approval` 查审批进度） |
| `detailUrl` | 单据详情 H5 地址 |
| `orderFields`（单据头） | 不同类型字段不同；采购申请单：申请人 `applyUserId/applyUserName`、申请总数/金额 `totalApplyNum/totalApplyAmount`、已开票 `totalBilledNum/totalBilledAmount/totalBilledRate`、已到货 `totalArrivedNum/totalArrivedRate`、已入库 `totalStorageNum/totalStorageRate`、已派发 `totalDistributedNum` |
| `lists`（单据明细） | 每行：档案 id `archiveId`、`code/name/brand/model/unit/photos`、申请 `applyPrice/applyNum/applyAmount`、已开票 `billedNum/billedAmount`、已到货 `arrivedNum`、未到货 `unArrivedNum`、已入库 `storageNum`、未入库 `unStorageNum`、已派发 `distributedNum` |

---

## 错误码

| 判定方式 | 说明 | 处理建议 |
|---|---|---|
| `code != "200"` 或 `success=false` | 业务失败，`msg` 为原因 | 按 `msg` 提示用户，勿重复盲目重试 |
| 业务错误码表 | 官方文档未给出具体业务码 | 常见场景按 `msg` 判断：单据不存在、formType 不合法、权限不足等 |

Token 失效（接口返回未授权）时：`bash scripts/gb_helper.sh --token --nocache` 强制刷新后重试。

---

## 所需应用权限

> 应用需具备采购单据模块的接口权限（开放平台创建应用时勾选）；返回权限不足时请在开放平台为应用补授权。
