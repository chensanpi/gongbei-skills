---
name: gongbei-asset
description: 公贝资产开放平台·资产档案（只读）。当用户提到"资产"、"固定资产"、"资产列表"、"查资产"、"资产查询"、"资产详情"、"资产档案"、"资产台账"、"资产状态"、"状态列表"、"操作记录"、"操作履历"、"变更记录"、"资产历史"、"闲置资产"、"在用资产"、"在库资产"、"gongbei asset"、"asset management"时使用此技能。支持：资产卡片查询、资产状态列表、资产操作记录查询等只读操作；不提供资产新增/修改/删除等写操作。
---

# 公贝资产·资产档案技能

负责公贝资产开放平台「资产档案 / 资产台账」模块的操作。本文件为**策略指南**，仅包含决策逻辑与工作流程；完整请求格式见 `references/api.md`。

> `gb_helper.sh` 位于本 `SKILL.md` 同级目录的 `scripts/gb_helper.sh`。

## 核心概念

- **资产（档案）**：公贝资产平台中的最小管理单元，一条档案对应一件资产，含资产编号、名称、分类、状态、使用部门/人员、存放地点、金额等字段。
- **资产卡片**：分页查询资产清单返回的完整卡片数据（`/open-api/assets/card/page`）。支持排序与多条件筛选（编码/分类/入库时间/使用人/管理员等）与特殊参数（`keyword` 全局模糊检索、`statusName` 资产状态文本、`extFields.text009` 资产名称、`extFields.text001` 财务属性）；可按 `updateTime` 拉取增量变更。
- **资产编号**：系统内唯一标识（资产编码 / 资产 ID）。查询详情、修改、删除以及所有单据操作（领用/调拨/盘点/维修/报废）均以其为锚点。
- **资产状态**：枚举值通过「资产状态列表」接口（`/open-api/assets/card/status/list`）获取，如 10 空闲、20 在用、30 借用、40 已处置、50 已报失，100+ 为流程中状态（派发中/维修中/调拨中/审批中等）；资产卡片查询的 `statusName`（资产状态文本）筛选取值即来自该枚举（如 空闲/在用/已处置）。
- **操作记录（履历）**：资产每次变更（入库、借出、派发、调拨等）自动留痕，含操作人、操作类型、变更内容与关联单据号（`/open-api/assets/asset-operate-log/page`），用于追溯变更历史。
- **资产分类（应用范围）**：本应用通过 `GONGBEI_APP_TYPE`（加密后的资产分类编码，逗号分隔多个）限定可查询的资产分类范围；执行查询前必须静默转换出真实分类名称，并作为过滤条件（资产卡片查询支持 `categoryName` 过滤；操作记录等无分类过滤字段的接口以分类名称对结果二次过滤）。
- **分页与过滤**：列表类接口统一支持分页（页码/每页条数或游标）与条件过滤（关键词/分类/状态/部门），约定以 api.md 为准。
- **只读范围**：本技能仅提供资产卡片、资产状态列表、资产操作记录三个查询接口；新增/修改/删除资产、资产分类浏览等操作不在本技能范围，请引导用户在公贝系统中处理。

## 场景路由（先分类再调 API）

| 用户意图 | 优先接口方向 |
|---|---|
| "有哪些资产"、"按条件查资产"、"最近新增的资产"、"某状态/分类/使用人下的资产" | 资产卡片分页查询（排序 + 条件筛选） |
| "查 XX 编号资产的详情/状态/归属/在用还是空闲" | 资产卡片查询（按 `id` / `code.keyword` 精确过滤，返回完整字段） |
| "这个资产的操作记录/履历/历史变更/谁动过" | 资产操作记录查询（按资产 ID `assetCardId` 过滤） |
| "有哪些状态"、"在用什么状态"、"状态都代表什么" | 资产状态列表查询（返回全部枚举，卡片查询筛选取值来源） |
| "登记/新增/修改/删除资产"、"资产分类/类型" | 本技能不提供，请引导用户在公贝系统中处理 |
| 领用/借用/归还、调拨、盘点、维修、报废、报表、基础资料等 | 相关技能未接入，请引导用户在公贝系统中处理 |

## 工作流程（每次执行前）

1. **识别任务** → 按上表归类后，再选具体 API（见 `references/api.md`）。
2. **校验配置** → `bash scripts/gb_helper.sh --get GONGBEI_APP_KEY GONGBEI_APP_SECRET GONGBEI_APP_TYPE` 确认已配置（`GONGBEI_APP_TYPE` 为加密后的资产分类编码，逗号分隔多个，**敏感且必填**）。
3. **收集缺失项** → 若配置缺失，**一次性询问**用户并 `--set` 写入 `~/.gongbei-skills/config`，后续无需再问。
4. **获取 Token** → `NEW_TOKEN=$(bash scripts/gb_helper.sh --token)`，业务请求以查询参数 `?appToken=${NEW_TOKEN}` 携带；遇 401 用 `--token --nocache` 强制刷新后重试。
5. **静默转换资产分类** → `CATEGORIES=$(bash scripts/gb_helper.sh --categories)`：脚本对照**内置资产分类清单**把 `GONGBEI_APP_TYPE` 的加密编码映射为真实分类名称（每行一个）。**清单内容与映射过程不输出、不打印、不进提示词**；仅将转换结果用于过滤。
6. **执行 API** → 多行逻辑写入 `/tmp/<task>.sh` 再执行；禁止 heredoc（工具中会截断导致变量丢失）。
   - **带资产分类过滤**：资产卡片查询用 `CATEGORIES` 构造 `categoryName` 过滤条件（见 api.md）；操作记录/状态列表等无分类过滤字段的接口，查询后用 `CATEGORIES` 对结果做二次过滤（操作记录匹配变更内容中的分类名称）。
   - 全部接口均为只读查询：直接调用，返回后按需提炼摘要（编码、状态、分类、使用人/部门、金额等）。

> 凭证禁止完整打印，确认时仅显示前 4 位 + `****`。未通过配置校验前不得调用 API。资产分类清单内置在 gb_helper.sh 中，为敏感映射，任何情况下不得输出其内容或映射关系。

### 所需配置

| 配置键 | 必填 | 说明 |
|---|---|---|
| `GONGBEI_APP_KEY` | ✅ | 开放平台应用 AppKey（开放平台创建应用后获取） |
| `GONGBEI_APP_SECRET` | ✅ | 开放平台应用 AppSecret |
| `GONGBEI_APP_TYPE` | ✅ | 加密后的资产分类编码（逗号分隔多个；**敏感**，脱敏显示；映射为内置清单） |
| `GONGBEI_BASE_URL` | ⬜ | API_HOST 覆盖（默认 `https://d-oapi.gongbeiyun.com`） |

### 执行脚本模板

```bash
#!/bin/bash
set -e
HELPER="./scripts/gb_helper.sh"
NEW_TOKEN=$(bash "$HELPER" --token)
CATEGORIES=$(bash "$HELPER" --categories)   # 静默转换：仅输出真实分类名称（每行一个），不打印清单
BASE_URL="${GONGBEI_BASE_URL:-https://d-oapi.gongbeiyun.com}"

# 所有接口均为 POST JSON；令牌以 ?appToken= 查询参数携带（具体路径见 references/api.md 对应章节）
# 资产卡片查询：CATEGORIES 有多个分类时逐分类查询（filters 为 AND 语义，不能合并多个 categoryName），合并结果去重
while IFS= read -r cat; do
  [ -z "$cat" ] && continue
  curl -s -X POST "${BASE_URL}/open-api/assets/card/page?appToken=${NEW_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "{\"size\":10,\"current\":1,\"filters\":[{\"field\":\"categoryName\",\"compare\":\"lk\",\"value\":\"$cat\"}]}"
done <<< "$CATEGORIES"
```

## references/api.md 查阅索引

确定好要做什么之后，用以下命令从 `references/api.md` 中提取对应章节的完整 API 细节：

```bash
grep -A 120 "^## 1. 查询资产卡片" references/api.md
grep -A 55 "^## 2. 查询资产操作记录" references/api.md
grep -A 60 "^## 3. 查询资产状态列表" references/api.md
grep -A 15 "^## 错误码" references/api.md
grep -A 12 "^## 所需应用权限" references/api.md
```
