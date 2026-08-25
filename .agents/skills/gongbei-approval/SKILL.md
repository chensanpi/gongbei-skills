---
name: gongbei-approval
description: 公贝资产开放平台·审批&待办中心（只读）。当用户提到"审批"、"审批中心"、"审批实例"、"审批单"、"审批列表"、"待办"、"我的待办"、"待办审批"、"审批待办"、"待办数量"、"流程审批"、"审批进度"、"gongbei approval"、"approval"、"workflow"、"todo"时使用此技能。支持：审批实例列表查询、用户审批待办列表查询等只读操作；不提供审批处理等写操作。
---

# 公贝资产·审批&待办中心技能

负责公贝资产开放平台「审批&待办中心」模块的**只读查询**。本文件为**策略指南**，仅包含决策逻辑与工作流程；完整请求格式见 `references/api.md`。

> `gb_helper.sh` 位于本 `SKILL.md` 同级目录的 `scripts/gb_helper.sh`。

## 核心概念

- **审批实例（process instance）**：一次审批流程的完整记录，含实例编码 `instanceCode`、标题、状态、发起人/发起部门、关联单据（`linkType` 单据类型 / `linkId` 单据 id / `linkCode` 单据编码）与审批摘要 `contentJson`。
- **实例状态**：`100` 进行中 / `200` 已拒绝 / `300` 已撤销 / `400` 已完结。
- **审批摘要（contentJson）**：`type` 为 `kv` 时取 `contentKv`（键值对数组），如「单据编号、申请人、申请部门」。
- **待办记录（record）**：待办列表条目含当前节点的处理记录 `record`（`status = 20` 处理中、审批人 `userName`/`userCode`、开始时间 `startTime`）。
- **人员/部门筛选**：人员字段可选 `id`、`code`、`name`、`phone`、`email`、`thirdUserId`；部门字段可选 `id`、`code`、`name`、`thirdOrgId`。
- **只读范围**：本技能仅提供审批实例列表与用户待办的查询；审批详情、已办、抄送、效率诊断及同意/驳回/撤销等操作不在本技能范围，请引导用户在公贝系统中处理。

## 场景路由（先分类再调 API）

| 用户意图 | 优先接口方向 |
|---|---|
| "有哪些审批"、"审批到哪一步了"、"按单据/发起人/状态筛审批" | 审批实例列表（分页 + filters 筛选） |
| "我的待办"、"我有哪些待审批"、"待办数量" | 用户审批待办列表（按人员过滤，可统计 total） |
| "帮我审批通过/驳回/撤销"（写操作） | 本技能不开放写操作，请引导用户在公贝系统中处理 |
| "查审批详情/已办/抄送/审批效率" | 本技能不提供，请引导用户在公贝系统中查看 |
| 查资产/单据本身的状态 | 对应业务技能（如 `gongbei-asset` / `gongbei-procurement`） |

## 工作流程（每次执行前）

1. **识别任务** → 按上表归类后，再选具体 API（见 `references/api.md`）。
2. **校验配置** → `bash scripts/gb_helper.sh --get GONGBEI_APP_KEY GONGBEI_APP_SECRET` 确认已配置。
3. **收集缺失项** → 若配置缺失，**一次性询问**用户并 `--set` 写入 `~/.gongbei-skills/config`。
4. **获取 Token** → `NEW_TOKEN=$(bash scripts/gb_helper.sh --token)`，业务请求以查询参数 `?appToken=${NEW_TOKEN}` 携带；遇 401 用 `--token --nocache` 强制刷新后重试。
5. **执行 API** → 多行逻辑写入 `/tmp/<task>.sh` 再执行；禁止 heredoc。
   - 全部接口均为只读查询：直接调用，返回后按需提炼摘要（单据编号、状态、发起人、关联单据）。

> 凭证禁止完整打印，确认时仅显示前 4 位 + `****`。未通过配置校验前不得调用 API。

### 所需配置

| 配置键 | 必填 | 说明 |
|---|---|---|
| `GONGBEI_APP_KEY` | ✅ | 开放平台应用 AppKey |
| `GONGBEI_APP_SECRET` | ✅ | 开放平台应用 AppSecret |
| `GONGBEI_BASE_URL` | ⬜ | API_HOST 覆盖（默认 `https://d-oapi.gongbeiyun.com`） |

### 执行脚本模板

```bash
#!/bin/bash
set -e
HELPER="./scripts/gb_helper.sh"
NEW_TOKEN=$(bash "$HELPER" --token)
BASE_URL="${GONGBEI_BASE_URL:-https://d-oapi.gongbeiyun.com}"

# 示例：查询审批实例列表（分页 + 状态筛选）
curl -s -X POST "${BASE_URL}/open-api/system/process-instance/page?appToken=${NEW_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"current":1,"size":10,"filters":[{"field":"status","compare":"in","value":[100,400]}]}'
```

## references/api.md 查阅索引

确定好要做什么之后，用以下命令从 `references/api.md` 中提取对应章节的完整 API 细节：

```bash
grep -A 60 "^## 1. 查询审批实例列表" references/api.md
grep -A 40 "^## 2. 查询用户审批待办列表" references/api.md
grep -A 15 "^## 错误码" references/api.md
grep -A 12 "^## 所需应用权限" references/api.md
```
