# 资产档案 API 参考

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

`success=true` 表示成功；成功数据在 `data`，失败原因在 `errMsg`。分页对象使用 `data.dataList` 和 `data.total`；状态列表使用 `data` 数组。

## 通用请求规则

- 分页字段：`current` 页码，默认 1；`size` 每页数量，默认 10，最大 1000。
- 列表过滤器：`filters` 数组，每项 `{field,compare,value}`；排序：`sorts` 数组，每项 `{field,direction}`。
- 比较符：`eq` 等于、`lk` 模糊、`in` 包含、`ni` 不包含、`bt` 区间、`gt`/`lt` 大于/小于、`ge`/`le` 大于等于/小于等于。
- 时间均为 Unix 毫秒时间戳。

## 1. 资产卡片分页

动作：`assetCardPage`

用途：查询资产台账、资产详情和按条件筛选的资产卡片。详情没有独立动作，通过 `id` 或 `code.keyword` 精确筛选。

请求体：

```json
{
  "current": 1,
  "size": 10,
  "keyword": "高德置地店",
  "sorts": [{"field": "id", "direction": "desc"}],
  "filters": [
    {"field": "code.keyword", "compare": "in", "value": ["GB-00040"]},
    {"field": "categoryName", "compare": "lk", "value": "办公设备"},
    {"field": "statusName", "compare": "lk", "value": "在用"},
    {"field": "storageTime", "compare": "bt", "value": [1690000000000, 1700000000000]},
    {"field": "extFields.text009", "compare": "lk", "value": "笔记本"},
    {"field": "extFields.text001", "compare": "lk", "value": "财务资产"}
  ]
}
```

### 筛选字段映射

| field | compare | value | 说明 |
|---|---|---|---|
| `id` | `in` | int[] | 资产 ID |
| `code` | `lk` | string | 资产编码模糊查询 |
| `code.keyword` | `in` | string[] | 资产编码精确查询 |
| `categoryId` | `in` | int[] | 分类 ID |
| `categoryName` | `lk` | string | 分类名称模糊查询 |
| `storageTime` | `bt` | long[2] | 入库时间范围 |
| `statusName` | `lk` | string | 状态文本，如空闲/在用/已处置 |
| `extFields.text009` | `lk` | string | 资产名称；替代原 `name` 筛选 |
| `extFields.text001` | `lk` | string | 财务属性：财务资产/非财务资产/临时通用类别 |
| `useUser.thirdUserId` | `in` | string[] | 使用人对接标识 |
| `admin.thirdUserId` | `in` | string[] | 资产管理员对接标识 |

`keyword` 是全局模糊检索，涉及资产所属门店或部门时可直接使用。人员属性还支持 `name`、`code`、`phone`、`email`、`thirdUserId`。

### 响应字段映射

`data.dataList[]` 关键字段：

- `id`：资产 ID；`code`/`oldCode`：资产编码/旧编码。
- `status`/`statusName`：状态值/状态描述。
- `categoryId`、`categoryCode`、`categoryName`：分类；另有一级分类 `firstCategoryCode`/`firstCategoryName`。
- `locationId`/`locationCode`/`locationName`：存放位置。
- `adminId`/`adminCode`/`adminName`：资产管理员。
- `useUserId`/`useUserCode`/`useUserName`：使用人；`useDepartmentId`/`useDepartmentCode`/`useDepartmentName`：使用部门。
- `companyId`/`companyCode`/`companyName`：所属公司。
- `storageTime`：入库时间；`buyDate`/`buySourceName`：购置时间/购置方式；`updateTime`：最后更新时间，可用于增量同步。
- `includeTaxPrice`/`excludeTaxPrice`：含税/不含税金额。
- `extProps`/`extFields`：扩展字段集合；字段编码需要通过已登记的表单字段结构动作查询，不要臆造字段名。

## 2. 资产操作记录

动作：`assetOperateLogPage`

用途：查询入库、借出、派发、调拨等变更履历，只读。

请求体：

```json
{
  "current": 1,
  "size": 10,
  "sorts": [{"field": "id", "direction": "desc"}],
  "filters": [
    {"field": "assetCardId", "compare": "in", "value": [23974]},
    {"field": "operationType", "compare": "eq", "value": 10},
    {"field": "operatorId", "compare": "eq", "value": 1100},
    {"field": "createTime", "compare": "bt", "value": [1690000000000, 1700000000000]}
  ]
}
```

常用过滤字段：`assetCardId` 资产 ID，`operationType` 操作类型，`operatorId` 操作人 ID，`createTime` 操作时间范围。

`data.dataList[]` 字段：`id`、`assetCardId`、`createTime`/`updateTime`、`operatorId`/`operatorName`、`operationType`/`operationTypeName`、`operationContent`、`operationRemark`、`relatedTargetId`。`operationContent` 是旧值到新值的变更明细，`relatedTargetId` 是关联单据编号。

## 3. 资产状态列表

动作：`assetStatusList`，请求体 `{}`。

`data` 为 `{code,desc}` 数组。状态包括：`10` 空闲、`20` 在用、`30` 借用、`40` 已处置、`50` 已报失、`100` 派发中、`110` 退库中、`120` 借出中、`130` 归还中、`140` 维修中、`150` 处置中、`160` 调拨中、`170` 批量修改中、`180` 领用人变更中、`190` 领用申请中、`200` 借用申请中、`210` 退还中、`220` 交接中、`230` 报修中、`240` 报失中、`250` 补充中、`260` 待处置、`270` 故障、`280` 校验中、`290` 保养中、`300` 主附调整中、`310` 盘亏中、`320` 共享申请中、`330` 更换中。

卡片查询中的 `statusName` 应使用本动作返回的 `desc`，例如“空闲”“在用”“已处置”。

## 响应组织

卡片提炼编码、名称、状态、分类、位置、使用人/部门、管理员、金额和 `data.total`；操作记录提炼时间、操作人、操作类型、变更内容和关联单据；状态查询返回完整枚举。失败时使用 `errMsg`，不要展示认证材料。
