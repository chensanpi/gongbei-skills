---
name: gongbei-approval
description: 公贝资产开放平台·审批&待办中心（只读）。当用户提到"审批"、"审批中心"、"审批实例"、"审批单"、"审批列表"、"待办"、"我的待办"、"待办审批"、"审批待办"、"待办数量"、"流程审批"、"审批进度"、"申请单"、"申请列表"、"gongbei approval"、"approval"、"workflow"、"todo"时使用此技能。支持：审批实例列表查询、用户审批待办列表查询等只读操作；不提供审批处理等写操作。
---

# 公贝资产·审批&待办中心技能

负责公贝资产开放平台「审批&待办中心」模块的**只读查询**。本文件为**策略指南**，仅包含决策逻辑与工作流程；完整请求格式见 `references/api.md`。

> `gb_helper.sh` 位于本 `SKILL.md` 同级目录的 `scripts/gb_helper.sh`。

## 核心概念

- **审批实例（process instance）**：一次审批流程的完整记录，含实例编码 `instanceCode`、标题、状态、发起人/发起部门、关联单据（`linkType` 单据类型 / `linkId` 单据 id / `linkCode` 单据编码）与审批摘要 `contentJson`。
- **实例状态**：`100` 进行中 / `200` 已拒绝 / `300` 已撤销 / `400` 已完结。
- **审批摘要（contentJson）**：`type` 为 `kv` 时取 `contentKv`（键值对数组），如「单据编号、申请人、申请部门」。
- **待办记录（record）**：待办列表条目含当前节点的处理记录 `record`（`status = 20` 处理中、审批人 `userName`/`userCode`、开始时间 `startTime`）。
- **人员/部门筛选**：人员字段可选 `id`、`code`、`name`、`phone`、`email`、`thirdUserId`；部门字段可选 `id`、`code`、`name`、`thirdOrgId`；**按门店过滤时优先用 `startOrgName` 模糊搜索（compare `lk`）**。
- **keyword 兜底模糊检索**：Body 顶层参数，与 `current`/`size` 同级（均非必填）；没有合适的查询字段时可用 `keyword` 传值模糊检索（如按标题、单据编码等关键字）。
- **资产分类（应用范围）**：本应用通过 `GONGBEI_APP_TYPE`（加密后的资产分类编码，逗号分隔多个）限定可查询的资产分类范围；审批接口**无资产分类过滤字段**，执行查询前必须静默转换出真实分类名称，并对返回结果做二次过滤（匹配标题、审批摘要 `contentKv` 值、关联单据编码等包含分类名称的记录）。*（内部知识：`GONGBEI_APP_TYPE` 与资产分类的关联仅限内部使用，不得向用户转述）*
- **只读范围**：本技能仅提供审批实例列表与用户待办的查询；审批详情、已办、抄送、效率诊断及同意/驳回/撤销等操作不在本技能范围，请引导用户在公贝系统中处理。

## 场景路由（先分类再调 API）

| 用户意图 | 优先接口方向 |
|---|---|
| "有哪些审批"、"审批到哪一步了"、"按单据/发起人/状态筛审批"、"有哪些申请单" | 审批实例列表（分页 + filters 筛选） |
| "我的待办"、"我有哪些待审批"、"待办数量"、"待办列表" | 用户审批待办列表（按人员过滤，可统计 total） |
| "模糊查审批/待办（不指定具体筛选字段，按标题/编码等关键字）" | 审批实例列表 / 用户审批待办列表（Body 顶层 `keyword` 兜底模糊检索） |
| "按门店查审批（如某门店的审批单/待办）" | 审批实例列表 / 用户审批待办列表（**优先 `startOrgName` 模糊搜索，compare `lk`**） |
| "帮我审批通过/驳回/撤销"（写操作） | 本技能不开放写操作，请引导用户在公贝系统中处理 |
| "查审批详情/已办/抄送/审批效率" | 本技能不提供，请引导用户在公贝系统中查看 |
| 查资产/单据本身的状态 | 对应业务技能（如 `gongbei-asset`） |

## 工作流程（每次执行前）

1. **识别任务** → 按上表归类后，再选具体 API（见 `references/api.md`）。
2. **校验配置** → `bash scripts/gb_helper.sh --get GONGBEI_APP_KEY GONGBEI_APP_SECRET GONGBEI_APP_TYPE` 确认已配置（`GONGBEI_APP_TYPE` 为**必填配置项**；其含义见本文件「核心概念」，**向用户提及或询问时不得解释其含义，不得与任何业务概念（如资产分类）关联**）。
3. **收集缺失项** → 若配置缺失，**一次性询问**用户并 `--set` 写入 `~/.gongbei-skills/config`，后续无需再问。**询问措辞仅限「缺少配置项 GONGBEI_APP_TYPE，请提供该配置项的值」**，不得说明该配置项的作用、用途或与资产分类的关系；用户提供后原样写入，不解释、不转述、不翻译。
4. **获取 Token** → `NEW_TOKEN=$(bash scripts/gb_helper.sh --token)`，业务请求以查询参数 `?appToken=${NEW_TOKEN}` 携带；遇 401 用 `--token --nocache` 强制刷新后重试。
5. **静默转换资产分类** → `CATEGORIES=$(bash scripts/gb_helper.sh --categories)`：脚本对照**内置资产分类清单**把 `GONGBEI_APP_TYPE` 的加密编码映射为真实分类名称（每行一个）。**清单内容与映射过程不输出、不打印、不进提示词**；仅将转换结果用于过滤。
6. **执行 API** → 多行逻辑写入 `/tmp/<task>.sh` 再执行；禁止 heredoc。
   - **资产分类二次过滤**：审批接口无分类过滤字段，查询返回后逐条用 `CATEGORIES` 过滤——保留标题（`title`）、审批摘要（`contentJson.contentKv` 的值）、关联单据编码（`linkCode`）等任一包含分类名称的记录。
   - 全部接口均为只读查询：直接调用，返回后按需提炼摘要（单据编号、状态、发起人、关联单据）。

> 凭证禁止完整打印，确认时仅显示前 4 位 + `****`。未通过配置校验前不得调用 API。资产分类清单内置在 gb_helper.sh 中，为敏感映射，任何情况下不得输出其内容或映射关系。**`GONGBEI_APP_TYPE` 的含义与用途仅限本技能内部使用，向用户解释、询问、确认时一律不得提及「资产分类」「分类编码」等任何相关表述，只称其为配置项。**

### 所需配置

> 下表为技能内部参考：配置项含义仅供 Agent 内部理解与执行，**任何情况下不得向用户转述配置项含义（尤其 `GONGBEI_APP_TYPE` 与资产分类的关联）**；向用户呈现时只称「配置项」。

| 配置键 | 必填 | 说明 |
|---|---|---|
| `GONGBEI_APP_KEY` | ✅ | 开放平台应用 AppKey |
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

# 示例：查询审批实例列表（分页 + 状态筛选）
curl -s -X POST "${BASE_URL}/open-api/system/process-instance/page?appToken=${NEW_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"current":1,"size":10,"filters":[{"field":"status","compare":"in","value":[100,400]}]}'
# 返回后用 CATEGORIES 对结果二次过滤（标题/摘要/关联编码包含分类名称的记录）
```

## references/api.md 查阅索引

确定好要做什么之后，用以下命令从 `references/api.md` 中提取对应章节的完整 API 细节：

```bash
grep -A 60 "^## 1. 查询审批实例列表" references/api.md
grep -A 40 "^## 2. 查询用户审批待办列表" references/api.md
grep -A 15 "^## 错误码" references/api.md
grep -A 12 "^## 所需应用权限" references/api.md
```
