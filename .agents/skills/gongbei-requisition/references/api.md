# 公贝资产·资产申购单 API 参考

> **接口通用约定**（官方文档：https://doc.gongbeiyun.com/web/#/5/689）
> - API_HOST：`https://d-oapi.gongbeiyun.com`（统一使用；可用 `GONGBEI_BASE_URL` 覆盖）
> - 所有接口均为 **POST JSON** 请求（`Content-Type: application/json`）
> - 鉴权：`POST {API_HOST}/open-api/auth/getAppToken`，Body `{"appKey":"...","appSecret":"..."}` → 返回 `data.appToken`（有效期以 `data.expireTime` 毫秒时间戳为准）。用 `gb_helper.sh --token` 获取并缓存
> - 业务请求携带令牌：查询参数 `?appToken=<token>`
> - 统一响应结构：`{"code":"200","msg":"成功","requestId":"...","data":{...},"success":true}`；`code` 非 `"200"` 或 `success=false` 即失败，按 `msg` 提示
> - **资产分类（应用范围）**：本应用经 `GONGBEI_APP_TYPE`（加密后的资产分类编码，逗号分隔多个，**敏感且必填**）限定资产分类范围；执行查询前先 `bash scripts/gb_helper.sh --categories` 静默转换出真实分类名称（对照本地清单 `~/.gongbei-skills/asset-category-map`，清单内容不输出）。**申购单查询**用转换结果构造扩展字段 `extFields.text034`（资产分类）过滤条件（compare 取 `IN`，多个分类名逗号分隔，见下方请求示例），返回后按 `lists.assetSnapshot.categoryName` 二次核对分类。
> - 时间均用**毫秒时间戳**；文档示例中的 `//` 注释实际请求时必须移除，否则 JSON 无法解析

---

## 1. 查询资产申购单

> 分页查询资产申购单据，`formType` **固定为 40**（必填），只读不创建业务单据；对接外部系统时同步业务单据。同一接口 `asset-order/page` 亦支持其它资产单据类型，本技能聚焦资产申购单。

**接口地址**：`POST {API_HOST}/open-api/asset-order/page?appToken=<token>`

| 参数 | 位置 | 必填 | 类型 | 说明 |
|---|---|---|---|---|
| `size` | Body | ⬜ | int | 每页条数，默认 10 |
| `current` | Body | ⬜ | int | 当前页码，默认 1 |
| `keyword` | Body | ⬜ | string | 模糊查询关键字 |
| `formType` | Body | ✅ | int | 单据类型：申购单**固定为 40** |
| `filters` | Body | ⬜ | array | 条件字段集合，元素 `{field, compare, value}`，见下方筛选字段与 compare 比较符 |

### 单据通用 filters 查询字段

| field | 类型 | value 示例 | 说明 |
|---|---|---|---|
| `code` | String | ZCRK202209160001 | 单据编码 |
| `orderStatus` | int | 400 | 单据状态：100 进行中 / 200 已拒绝 / 300 已撤销 / 400 已完结 / 600 待提交 |
| `startOrgId` | long | 1652829933 | 发起人组织 id（参照：员工分页查询、部门分页查询） |
| `startOrgName` | String | 研发部 | 发起人组织名称 |
| `startUserId` | long | 123423422 | 发起人员 id |
| `startUserName` | String | 张三 | 发起人员名称 |
| `linkOrderCode` | String | ZCBF01000030022 | 关联单据编号 |
| `remark` | String | 测试 | 备注 |
| `processInstanceId` | String | GB-10003-2003333 | 审批实例 ID |

### 申购单 filters 查询字段（formType=40）

| field | 类型 | value 示例 | 说明 |
|---|---|---|---|
| `orderFields.operateTime` | long | 134334333232 | 申请时间（时间戳） |
| `orderFields.purchaseSumCount` | int | 1 | 申购总数量 |
| `orderFields.purchaseSumAmount` | double | 99.81 | 申购总金额 |
| `orderFields.waitStorageSumCount` | long | 1 | 待入库总数量 |

### 扩展字段映射（查询与返回结果通用）

申购单自定义扩展字段，**既可用于 filters 查询，也可用于返回结果映射**（响应 `extFields` 对象中按相同键取对应值）：

| 扩展字段 | 含义 | 说明 |
|---|---|---|
| `extFields.text029` | 具体说明 | 普通文本 |
| `extFields.text034` | 资产分类 | 普通文本 |
| `extFields.text042` | 申请原因 | 普通文本 |
| `extFields.text046` | 部门现有资产 | 表格 |


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

查询示例（按资产分类筛申购单）：

```json
{
  "size": 10,
  "current": 1,
  "formType": 40,
  "filters": [
    { "field": "extFields.text034", "compare": "IN", "value": "工程设备,工程设施" }
  ]
}
```

### 响应示例（资产申购单 formType=40）

```json
{
  "code": "200",
  "msg": "成功",
  "requestId": "2faec681-d5df-48b1-82b3-930b3a83f626",
  "success": true,
  "data": {
    "size": 10,
    "current": 1,
    "total": 1,
    "dataList": [
      {
        "createTime": 1663312489000,
        "updateTime": 1663312490000,
        "id": "1570672540454621186",
        "corpId": "139",
        "formType": 40,
        "name": "资产申购单",
        "code": "ZCRK202209160001",
        "formConfigId": "1564588469718749185",
        "processType": 0,
        "orderStatus": 400,
        "orderStatusName": "已完结",
        "startOrgId": "2814",
        "startOrgName": "部门1",
        "startUserId": "1306",
        "startUserName": "82年滴矿泉水",
        "linkOrderCode": "",
        "remark": "导入资产",
        "processInstanceId": "gb-0a00f-221b-40b1-bc91-96fb39c1c61f",
        "dingInstanceUrl": "",
        "visibleUserIds": ["1306"],
        "orderFields": {
          "operateTime": 1663312489950,
          "operateUserId": "1306",
          "operateUserName": "82年滴矿泉水",
          "relatedOrderId": "1570672540244905986",
          "formType": 1
        },
        "extFields": {
          "text029": "具体说明示例",
          "text034": "电脑类",
          "text042": "报废新购",
          "text046": []
        },
        "lists": []
      }
    ]
  }
}
```

### 关键字段说明

| 字段 | 说明 |
|---|---|
| `code` / `name` | 单据编码 / 单据类型名称（资产申购单） |
| `formType` | 单据类型（申购单固定 40） |
| `orderStatus` / `orderStatusName` | 单据状态 / 描述（100 进行中 / 200 已拒绝 / 300 已撤销 / 400 已完结 / 600 待提交） |
| `startOrgId/Name`、`startUserId/Name` | 发起部门 / 发起人 |
| `linkOrderCode` | 关联单据号（可为空） |
| `remark` | 备注 |
| `processInstanceId` | 审批实例 ID（可关联 `gongbei-approval` 查审批进度） |
| `visibleUserIds` | 可见人员范围 |
| `orderFields`（单据头） | 申请时间 `operateTime`、申请人 `operateUserId/operateUserName`、关联单据 `relatedOrderId/formType`；申购单汇总（可筛选）：申购总数量 `purchaseSumCount`、申购总金额 `purchaseSumAmount`、待入库总数量 `waitStorageSumCount` |
| `lists`（单据明细） | 每行含资产快照 `assetSnapshot`：资产 `id/code/name/brand/model/deviceSn/oldCode`、分类 `categoryId/categoryName`、位置 `locationId/locationName`、管理员 `adminId/adminName`、所属公司 `companyId/companyName`、入库时间 `storageTime` |
| `extFields`（扩展字段） | 自定义扩展字段值（映射见「扩展字段映射」）：具体说明 `text029`、资产分类 `text034`、申请原因 `text042`、部门现有资产 `text046`（表格类型） |

---

## 错误码

| 判定方式 | 说明 | 处理建议 |
|---|---|---|
| `code != "200"` 或 `success=false` | 业务失败，`msg` 为原因 | 按 `msg` 提示用户，勿重复盲目重试 |
| 业务错误码表 | 官方文档未给出具体业务码 | 常见场景按 `msg` 判断：单据不存在、formType 不合法、权限不足等 |

Token 失效（接口返回未授权）时：`bash scripts/gb_helper.sh --token --nocache` 强制刷新后重试。

---

## 所需应用权限

> 应用需具备资产申购单模块的接口权限（开放平台创建应用时勾选）；返回权限不足时请在开放平台为应用补授权。
