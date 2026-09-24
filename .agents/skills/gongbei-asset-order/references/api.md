# 资产单据通用 API 参考

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

## 资产单据分页

动作：`assetOrderPage`。分页查询资产单据，`formType` 必填且一次只能传一个，用于筛某一类单据。只读，不创建或修改单据。

请求体：

```json
{
  "current": 1,
  "size": 10,
  "formType": 2,
  "keyword": "可选关键字",
  "filters": [
    {"field": "code", "compare": "LK", "value": "ZCRK202209160001"},
    {"field": "orderStatus", "compare": "EQ", "value": 400},
    {"field": "linkOrderCode", "compare": "EQ", "value": "ZCBF01000030022"}
  ]
}
```

- `size` 每页条数，默认 10；`current` 当前页码，默认 1；`keyword` 非必填的概念检索。
- `filters[].field` 字段名，`compare` 比较符，`value` 值对象。

## formType 速查表

| formType | 单据名称 |
|---|---|
| 2 | 入库单 |
| 3 | 借用单 |
| 4 | 归还单 |
| 5 | 派发单 |
| 6 | 退库单 |
| 7 | 调拨单 |
| 8 | 维修单 |
| 9 | 处置单 |
| 10 | 批量修改单 |
| 31 | 领用申请单 |
| 34 | 资产报修单 |
| 36 | 资产退还单 |

`formType` 取值以本表为准；接口文档示例注释中出现过的 `formType: 101` 未被字段表收录，不要使用。

## 比较符

`EQ` 等于、`LT` 小于、`GT` 大于、`LE` 小于等于、`GE` 大于等于、`NE` 不等于、`LK` 模糊、`NLK` 不模糊、`LFK` 左模糊、`RHK` 右模糊、`INL` 为空、`NNL` 非空、`IN` 批量精确匹配、`NI` 不在其中、`BT` 区间。

`EQ`/`NE` 支持字符、数值、日期；`LT`/`GT`/`LE`/`GE`/`BT` 仅数值和日期；`LK`/`NLK`/`LFK`/`RHK` 仅字符；`INL`/`NNL`/`IN`/`NI` 支持字符、数值、日期。`BT` 传两元素数组，`IN`/`NI` 传数组或多值。

单据状态：`100` 进行中、`200` 已拒绝、`300` 已撤销、`400` 已完结、`600` 待提交。

## 通用单据字段（所有 formType 可用）

| field | 类型 | 说明 |
|---|---|---|
| `code` | String | 单据编码 |
| `orderStatus` | int | 单据状态 |
| `startOrgId` / `startOrgName` | long/String | 发起人组织 ID / 名称 |
| `startUserId` / `startUserName` | long/String | 发起人 ID / 名称 |
| `linkOrderCode` | String | 关联单据编号 |
| `remark` | String | 备注 |
| `processInstanceId` | String | 审批实例 ID，可交给 `gongbei-approval` 查审批进度 |

## 各类型专属字段

只使用与当前 `formType` 匹配的一段。

### 入库单（formType=2）

| field | 类型 | 说明 |
|---|---|---|
| `orderFields.operateTime` | long | 入库时间，毫秒时间戳 |
| `orderFields.operateUserId` / `orderFields.operateUserName` | long/String | 入库处理人 ID / 姓名 |
| `orderFields.relatedOrderId` | long | 关联单据 ID |

### 借用单（formType=3）

| field | 类型 | 说明 |
|---|---|---|
| `orderFields.afterUseUserId` / `orderFields.afterUseUserName` | long/String | 借用人 ID / 姓名 |
| `orderFields.afterUseDepartmentId` / `orderFields.afterUseDepartmentName` | long/String | 借用后部门 ID / 名称 |
| `orderFields.afterUseCompanyId` / `orderFields.afterUseCompanyName` | long/String | 借用后公司 ID / 名称 |
| `orderFields.afterLocationId` / `orderFields.afterLocationName` | long/String | 借用后位置 ID / 名称 |
| `orderFields.operateTime` | long | 借出时间，毫秒时间戳 |
| `orderFields.operateUserId` / `orderFields.operateUserName` | long/String | 借出处理人 ID / 姓名 |

### 归还单（formType=4）

| field | 类型 | 说明 |
|---|---|---|
| `orderFields.operateUserId` / `orderFields.operateUserName` | long/String | 归还处理人 ID / 姓名 |
| `orderFields.operateTime` | long | 归还时间，毫秒时间戳 |
| `orderFields.afterLocationId` / `orderFields.afterLocationName` | long/String | 归还后位置 ID / 名称 |
| `orderFields.afterUseDepartmentId` / `orderFields.afterUseDepartmentName` | long/String | 归还后使用部门 ID / 名称 |
| `orderFields.afterUseCompanyId` / `orderFields.afterUseCompanyName` | long/String | 归还后使用公司 ID / 名称 |

### 派发单（formType=5）

| field | 类型 | 说明 |
|---|---|---|
| `orderFields.afterUseUserId` / `orderFields.afterUseUserName` | long/String | 领用人 ID / 姓名 |
| `orderFields.afterUseDepartmentId` / `orderFields.afterUseDepartmentName` | long/String | 领用后部门 ID / 名称 |
| `orderFields.afterUseCompanyId` / `orderFields.afterUseCompanyName` | long/String | 领用后公司 ID / 名称 |
| `orderFields.afterLocationId` / `orderFields.afterLocationName` | long/String | 领用后位置 ID / 名称 |
| `orderFields.operateTime` | long | 派发时间，毫秒时间戳 |
| `orderFields.operateUserId` / `orderFields.operateUserName` | long/String | 派发处理人 ID / 姓名 |
| `orderFields.receiveCode` | String | 领用申请单单号 |
| `orderFields.receiveId` | long | 领用申请单 ID |

### 退库单（formType=6）

字段与归还单一致：`orderFields.operateUserId`/`orderFields.operateUserName`、`orderFields.operateTime`、`orderFields.afterLocationId`/`orderFields.afterLocationName`、`orderFields.afterUseDepartmentId`/`orderFields.afterUseDepartmentName`、`orderFields.afterUseCompanyId`/`orderFields.afterUseCompanyName`（退库时间与退库后归属）。

### 调拨单（formType=7）

| field | 类型 | 说明 |
|---|---|---|
| `orderFields.outAdminId` / `orderFields.outAdminName` | long/String | 调出管理员 ID / 姓名 |
| `orderFields.outTime` | long | 调出时间，毫秒时间戳 |
| `orderFields.outCompanyId` / `orderFields.outCompanyName` | long/String | 调出公司 ID / 名称 |
| `orderFields.outDepartmentId` / `orderFields.outDepartmentName` | long/String | 调出部门 ID / 名称 |
| `orderFields.outLocationId` / `orderFields.outLocationName` | long/String | 调出位置 ID / 名称 |
| `orderFields.inAdminId` / `orderFields.inAdminName` | long/String | 调入管理员 ID / 姓名 |
| `orderFields.inTime` | long | 调入时间，毫秒时间戳 |
| `orderFields.inCompanyId` / `orderFields.inCompanyName` | long/String | 调入公司 ID / 名称 |
| `orderFields.inDepartmentId` / `orderFields.inDepartmentName` | long/String | 调入部门 ID / 名称 |
| `orderFields.inLocationId` / `orderFields.inLocationName` | long/String | 调入位置 ID / 名称 |
| `transferRemark` | String | 调拨备注 |

### 维修单（formType=8）

| field | 类型 | 说明 |
|---|---|---|
| `orderFields.reportRepairUserId` / `orderFields.reportRepairUserName` | long/String | 报修人 ID / 姓名 |
| `orderFields.reportRepairDepartmentId` / `orderFields.reportRepairDepartmentName` | long/String | 报修部门 ID / 名称 |
| `orderFields.reportRepairTime` | long | 报修时间，毫秒时间戳 |
| `orderFields.reportRepairReason` | String | 报修原因 |
| `orderFields.repairUserId` / `orderFields.repairUserName` | long/String | 维修处理人 ID / 姓名 |
| `orderFields.expectRepairPrice` | double | 预计维修金额 |
| `orderFields.repairPrice` | double | 实际维修金额 |
| `orderFields.repairContent` | String | 维修内容 |

### 处置单（formType=9）

| field | 类型 | 说明 |
|---|---|---|
| `orderFields.disposeType` | String | 处置类型：`ZCBF` 资产报废、`PKCL` 盘亏处理、`ZRCS` 转让出售、`TZ` 退租 |
| `orderFields.disposeTypeName` | String | 处置类型名称 |
| `orderFields.disposePrice` | double | 处置金额 |
| `orderFields.disposeCost` | double | 处置费用 |
| `orderFields.disposeReason` | String | 处置原因 |
| `orderFields.operateTime` | long | 处置时间，毫秒时间戳 |
| `orderFields.originPriceTotal` | double | 原值合计 |
| `orderFields.depreciationResidualTotal` | double | 残值合计 |

### 批量修改单（formType=10）

| field | 类型 | 说明 |
|---|---|---|
| `orderFields.operateTime` | long | 批量修改时间，毫秒时间戳 |
| `orderFields.operateUserId` / `orderFields.operateUserName` | long/String | 批量修改处理人 ID / 姓名 |

### 领用申请单（formType=31）

| field | 类型 | 说明 |
|---|---|---|
| `orderFields.operateTime` | long | 申请时间，毫秒时间戳 |
| `orderFields.applySumCount` | int | 申请总数量 |
| `orderFields.waitDistributeSumCount` | int | 待派发总数量 |

### 资产报修单（formType=34）

| field | 类型 | 说明 |
|---|---|---|
| `orderFields.operateTime` | long | 申请时间，毫秒时间戳 |
| `orderFields.expectRepairPrice` | double | 预计维修金额 |

### 资产退还单（formType=36）

| field | 类型 | 说明 |
|---|---|---|
| `orderFields.operateTime` | long | 申请时间，毫秒时间戳 |
| `orderFields.afterLocationId` / `orderFields.afterLocationName` | long/String | 归还后位置 ID / 名称 |
| `orderFields.afterUseDepartmentId` / `orderFields.afterUseDepartmentName` | long/String | 归还后使用部门 ID / 名称 |
| `orderFields.afterUseCompanyId` / `orderFields.afterUseCompanyName` | long/String | 归还后使用公司 ID / 名称 |

## 单据明细字段（所有 formType 可用）

| field | 类型 | 说明 |
|---|---|---|
| `lists.assetSnapshot.id` | long | 资产 ID |
| `lists.assetSnapshot.code` / `lists.assetSnapshot.oldCode` | String | 资产编码 / 旧编码 |
| `lists.assetSnapshot.name` | String | 资产名称 |
| `lists.assetSnapshot.categoryId` / `lists.assetSnapshot.categoryName` | long/String | 资产分类 ID / 名称 |
| `lists.assetSnapshot.locationId` / `lists.assetSnapshot.locationName` | long/String | 位置 ID / 名称 |
| `lists.assetSnapshot.adminId` / `lists.assetSnapshot.adminName` | long/String | 管理员 ID / 名称 |
| `lists.assetSnapshot.companyId` / `lists.assetSnapshot.companyName` | long/String | 所属公司 ID / 名称 |
| `lists.assetSnapshot.storageTime` | long | 入库时间，毫秒时间戳 |
| `lists.assetSnapshot.brand` / `lists.assetSnapshot.model` | String | 品牌 / 型号 |
| `lists.assetSnapshot.deviceSn` | String | 序列号 |

## 关联单据编号

单据间的关联关系只从以下已文档化字段读取，不要臆造关联动作或字段：

| 来源 | 字段 | 说明 |
|---|---|---|
| 单据表头 | `linkOrderCode` | 关联单据编号，可为空字符串 |
| 单据头 `orderFields` | `relatedOrderId` | 关联单据 ID（入库单等） |
| 单据头 `orderFields` | `receiveCode` / `receiveId` | 领用申请单单号 / ID（派发单） |

双向查找方式：

- 从单据找它的关联单据：直接读该单据的 `linkOrderCode`；为空说明没有关联单据，如实说明，不要补默认值。
- 从关联单据反查哪些单据指向它：在目标单据类型上用 `filters` 传 `{"field":"linkOrderCode","compare":"LK","value":"<单据编码>"}`（编码确定时用 `EQ`）。`linkOrderCode` 不区分单据类型，需要覆盖多种类型时逐个 `formType` 查询，一次一个。
- 只知道 `relatedOrderId`/`receiveId` 等 ID 时：接口没有按单据 `id` 过滤的字段，不要伪造 `filters` 项；可改用 `orderFields.receiveCode`（派发单带单号）或请用户提供单据编码，再按编码查。
- 需要审批进度时把 `processInstanceId` 交给 `gongbei-approval`，不要在本动作里找审批字段。

## 响应字段映射

`data.dataList[]` 关键字段：

- `id`、`name`、`code`、`formType`、`formConfigId`、`processType`：单据标识与模板。
- `createTime`、`updateTime`：创建 / 更新时间，毫秒时间戳。
- `orderStatus` / `orderStatusName`：单据状态码与名称。
- `startOrgId` / `startOrgName`、`startUserId` / `startUserName`：发起组织与发起人。
- `corpId`：组织 ID；`visibleUserIds`：可见人员范围。
- `linkOrderCode`、`remark`、`processInstanceId`、`dingInstanceUrl`：关联单据编号、备注、审批实例 ID、外部实例地址。
- `orderFields`：单据头信息，按 formType 读取对应专属字段（操作人、时间、部门/位置/公司、汇总数量金额等）。
- `lists[]`：单据明细数组，每行的 `assetSnapshot` 为资产快照，按上方明细字段读取。

## 响应组织

普通查询提炼单据编码、单据类型、状态、发起人/部门、创建时间、备注、关联单据编号和 `processInstanceId`；用户要求明细时展开 `lists[].assetSnapshot` 的资产编码、名称、分类、位置、管理员和公司；用户问关联关系时同时给出 `linkOrderCode` 与反查命中的单据编码及其类型。始终报告 `data.total`，失败时使用 `errMsg`，不要展示认证材料。
