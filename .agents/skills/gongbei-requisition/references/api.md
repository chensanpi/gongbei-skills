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

动作：`assetOrderPage`。这是资产单据通用分页动作：查询申购单时 `formType` **固定为 `40`**；查询申购单的关联单据时，按关联单据类型传对应 `formType`（见下方「关联单据」）。

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
    {"field": "linkOrderCode", "compare": "LK", "value": "ZCRK202209160001"},
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

## 关联单据

申购单与其关联单据的关系只从下列已文档化字段读取，不要臆造字段或动作：

| 来源 | 字段 | 说明 |
|---|---|---|
| 单据表头 | `linkOrderCode` | 关联单据编号，可为空字符串 |
| 单据头 `orderFields` | `relatedOrderId` | 关联单据 ID |
| 单据头 `orderFields` | `formType` | 与 `relatedOrderId` 一起返回，标识该关联的来源单据类型 |

查找方式均使用同一动作 `assetOrderPage`：

1. 这张申购单关联了什么：先读表头 `linkOrderCode`；为空时读 `orderFields.relatedOrderId`，如实给出关联单据 ID，不要补默认值或虚构单号。
2. 这张申购单后续产生了哪些单据：把 `formType` 换成关联单据的类型，例如入库单用 `2`，再用 `{"field":"orderFields.relatedOrderId","compare":"EQ","value":"<申购单 id>"}` 过滤。`orderFields.relatedOrderId` 是否可过滤以该类型字段表为准（入库单已文档化支持）。
3. 按单号反查：`{"field":"linkOrderCode","compare":"LK","value":"<申购单编码>"}`，编码确定时用 `EQ`。`linkOrderCode` 不区分单据类型，需要覆盖多个类型时逐个 `formType` 查询，一次一个。
4. 接口没有按单据 `id` 过滤的字段，不要为「用 ID 查单据」伪造 `filters` 项。
5. 用于反查的关联单据类型（入库单、借用单、派发单等）其专属字段以 `gongbei-asset-order` 的 `references/api.md` 为准，本文件不重复定义。
6. 需要审批进度时把 `processInstanceId` 交给 `gongbei-approval`。

## 响应字段映射

`data.dataList[]` 关键字段：

- `id`、`name`、`code`、`formType`：单据标识；`formType` 应为 40。
- `orderStatus`/`orderStatusName`：单据状态；`startOrgId`/`startOrgName`、`startUserId`/`startUserName`：发起组织/人员。
- `linkOrderCode`、`remark`、`processInstanceId`：关联单据编号、备注、审批实例 ID。
- `orderFields`：单据头；包含申请时间 `operateTime`、申请人 `operateUserId`/`operateUserName`、关联单据 `relatedOrderId` 及其 `formType`，以及申购汇总字段 `purchaseSumCount`、`purchaseSumAmount`、`waitStorageSumCount`。
- `extFields`：扩展字段，按上方 `text029`/`text034`/`text042`/`text046` 映射读取。
- `lists`：单据明细数组。每行的 `assetSnapshot` 是资产快照，包含 `id`、`code`、`name`、`brand`、`model`、`deviceSn`、`oldCode`、`categoryId`/`categoryName`、`locationId`/`locationName`、`adminId`/`adminName`、`companyId`/`companyName`、`storageTime`。

## 响应组织

普通查询提炼单据编码、状态、申请人/部门、申请时间、申购总数量/金额、待入库数量、`linkOrderCode` 和 `processInstanceId`；用户问关联单据时按「关联单据」给出关联单据编号、关联单据 ID 及反查命中的单据编码和类型；用户要求明细时展开 `lists[].assetSnapshot` 的资产编码、名称、分类、位置、管理员和公司。始终报告 `data.total`，失败时使用 `errMsg`，不要展示认证材料。
