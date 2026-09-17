# 资产申购单 API 参考

认证、网关地址和请求头由 `gongbei-shared` 与 hun-cli 处理。当前动作使用：`hun post gongbei assetOrderPage -d '<JSON>'`。动作、字段和比较符以本文件为准。

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

`success=true` 表示成功；成功数据在 `data`，失败原因在 `errMsg`。分页列表在 `data.dataList`，总数在 `data.total`。

## 资产申购单分页

动作：`assetOrderPage`。这是资产单据通用分页动作，本技能只查询申购单，因此 `formType` **必须固定为 `40`**。

请求体：

```json
{
  "current": 1,
  "size": 10,
  "formType": 40,
  "keyword": "可选关键字",
  "filters": [
    {"field": "code", "compare": "LK", "value": "ZCRK202209160001"},
    {"field": "orderStatus", "compare": "EQ", "value": 400},
    {"field": "startOrgName", "compare": "LK", "value": "研发部"},
    {"field": "orderFields.operateTime", "compare": "BT", "value": [1690000000000, 1700000000000]},
    {"field": "orderFields.purchaseSumCount", "compare": "GE", "value": 1},
    {"field": "extFields.text042", "compare": "LK", "value": "报废新购"}
  ]
}
```

### 通用单据字段

| field | 类型 | 说明 |
|---|---|---|
| `code` | string | 单据编码 |
| `orderStatus` | int | 单据状态 |
| `startOrgId` / `startOrgName` | long/string | 发起组织 ID/名称 |
| `startUserId` / `startUserName` | long/string | 发起人 ID/名称 |
| `linkOrderCode` | string | 关联单据编号 |
| `remark` | string | 备注 |
| `processInstanceId` | string | 审批实例 ID，可交给审批技能查询进度 |

### 申购专属字段

| field | 类型 | 说明 |
|---|---|---|
| `orderFields.operateTime` | long | 申请时间，毫秒时间戳 |
| `orderFields.purchaseSumCount` | int | 申购总数量 |
| `orderFields.purchaseSumAmount` | double | 申购总金额 |
| `orderFields.waitStorageSumCount` | long | 待入库总数量 |

### 扩展字段映射

这些字段既可用于 `filters`，也从返回对象的 `extFields` 读取：

| 字段 | 含义 | 类型 |
|---|---|---|
| `extFields.text029` | 具体说明 | 文本 |
| `extFields.text034` | 资产分类 | 文本 |
| `extFields.text042` | 申请原因 | 文本 |
| `extFields.text046` | 部门现有资产 | 表格 |

按资产分类筛选时使用 `extFields.text034`，多个分类可用 `IN` 和逗号分隔的分类名称；不要把分类值放到不存在的 `categoryName` 字段。

### 比较符

接口比较符使用大写：`EQ` 等于、`LT` 小于、`GT` 大于、`LE` 小于等于、`GE` 大于等于、`NE` 不等于、`LK` 模糊、`NLK` 不模糊、`LFK` 左模糊、`RHK` 右模糊、`INL` 为空、`NNL` 非空、`IN` 批量精确匹配、`NI` 不在其中、`BT` 区间。

状态：`100` 进行中、`200` 已拒绝、`300` 已撤销、`400` 已完结、`600` 待提交。

## 响应字段映射

`data.dataList[]` 关键字段：

- `id`、`name`、`code`、`formType`：单据标识；`formType` 应为 40。
- `orderStatus`/`orderStatusName`：单据状态；`startOrgId`/`startOrgName`、`startUserId`/`startUserName`：发起组织/人员。
- `linkOrderCode`、`remark`、`processInstanceId`：关联单号、备注、审批实例 ID。
- `orderFields`：单据头；包含申请时间 `operateTime`、申请人 `operateUserId`/`operateUserName`、`relatedOrderId`，以及申购汇总字段 `purchaseSumCount`、`purchaseSumAmount`、`waitStorageSumCount`。
- `extFields`：扩展字段，按上方 `text029`/`text034`/`text042`/`text046` 映射读取。
- `lists`：单据明细数组。每行的 `assetSnapshot` 是资产快照，包含 `id`、`code`、`name`、`brand`、`model`、`deviceSn`、`oldCode`、`categoryId`/`categoryName`、`locationId`/`locationName`、`adminId`/`adminName`、`companyId`/`companyName`、`storageTime`。

## 响应组织

普通查询提炼单据编码、状态、申请人/部门、申请时间、申购总数量/金额、待入库数量和 `processInstanceId`；用户要求明细时展开 `lists[].assetSnapshot` 的资产编码、名称、分类、位置、管理员和公司。始终报告 `data.total`，失败时使用 `errMsg`，不要展示认证材料。
