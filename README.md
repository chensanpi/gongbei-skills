# 公贝资产 Agent 技能库（gongbei-skills）

中文 | [English](README_EN.md)

---

让 AI Agent 直接操作【公贝资产开放平台】——无需手写 API 调用，无需手动管理 Token，对话即操作。

基于 [Anthropic skills 规范](https://github.com/anthropics/skills) 构建，**仅依赖 `curl`**，无需安装 Python、SDK 或任何第三方库。安装后 Agent 即可理解"什么时候该调公贝 API、该调哪个、参数怎么填"，并**自动管理配置**、错误处理。

> 📌 **已实现能力**：基于官方文档（https://doc.gongbeiyun.com/web/#/5/640）实现**鉴权链路**与**通用约定**：API_HOST（统一 `https://d-oapi.gongbeiyun.com`）、`getAppToken` 换取 appToken（`?appToken=` 查询参数携带）、统一响应结构、表单字段结构查询与自定义字段（extFields）赋值规则。技能库提供三个模块：**审批&待办中心（gongbei-approval，只读）**：审批实例列表、用户审批待办列表；**资产档案（gongbei-asset，只读）**：资产卡片分页查询、资产状态列表、资产操作记录；**资产申购单（gongbei-requisition，只读）**：申购单分页查询（formType=40，含申请时间/采购总数量/采购总金额/待入库总数量筛选）。其余业务模块（采购/领用/调拨/盘点/维修/报废/报表/基础资料等）当前未纳入技能库，按需接入（接口路径与参数待官方文档公开后补充）。

## 为什么用这个

- **对话即操作**："帮我查一下财务部有哪些在用资产" → Agent 自动完成，无需你知道任何 API
- **零依赖**：仅使用 `curl` 发起 HTTP 请求，无需安装 Python、SDK 或任何第三方库
- **一次配置，永久生效**：首次使用时 Agent 统一询问 appKey/appSecret，写入 `~/.gongbei-skills/config`，后续所有技能直接复用，不再重复问

## 长期目标

本项目有两条并行的长期主线：

**1. 永远只依赖 `curl`**
不引入任何 SDK、运行时或第三方库。只要系统有 `curl`，技能就能运行。这保证了最大的可移植性，也让技能在任何 Agent 环境中都能免安装直接使用。

**2. 将每次调用消耗的 Token 压到极限**
Agent 每次执行任务都需要将技能文件装入上下文，**skill 文件本身就是成本**。我们的目标不只是「能用」，而是在保证正确率的前提下，把 `SKILL.md` 和 `references/api.md` 写得尽可能精炼——删掉所有冗余解释，用最短的指令表达最完整的语义。

## 技能纵览

| 技能 | 状态 | 说明 |
|---|---|---|
| [gongbei-asset](#gongbei-asset--资产档案) | ✅ 已上线 | 资产档案（只读）：资产卡片查询、资产状态列表、资产操作记录 |
| [gongbei-approval](#gongbei-approval--审批待办中心) | ✅ 已上线 | 审批&待办中心（只读）：审批实例列表、用户审批待办列表 |
| [gongbei-requisition](#gongbei-requisition--资产申购单) | ✅ 已上线 | 资产申购单（只读）：申购单分页查询（formType=40） |

## 快速开始

### 前置条件

1. 在[公贝资产开放平台](https://doc.gongbeiyun.com/web/#/5/640)创建应用：首页 Logo 右键进入「开放平台」页签 → 新建应用 → 获取应用的 `appKey`、`appSecret`
2. API_HOST 统一为 `https://d-oapi.gongbeiyun.com`，无需配置（如需覆盖可用 `GONGBEI_BASE_URL` 环境变量）
3. 准备好应用的 `appKey`、`appSecret`（Agent 会引导你完成配置）

### 安装技能

统一使用 `npx skills` 安装，支持 Cursor / Claude / Copilot / 🦞 OpenClaw / Hermes 等几乎所有 Agent：

```bash
# 安装单个技能
npx skills add https://github.com/chensanpi/gongbei-skills.git --skill gongbei-asset

# 一键安装全部技能（自动装到所有支持的 Agent 平台，无需逐个列出）
npx skills add https://github.com/chensanpi/gongbei-skills.git --all

# 指定只安装到某个 Agent（示例：仅 Claude Code）
npx skills add https://github.com/chensanpi/gongbei-skills.git --skill '*' -a claude-code
```

> 仓库托管于 GitHub（https://github.com/chensanpi/gongbei-skills）。上架 ClawHub / skills.sh 后亦可平台一键安装。

### 开口说话

安装后，Agent 会在首次运行时检查 `~/.gongbei-skills/config`，缺什么一次性问清楚，自动写入。之后直接对话：

```
"查一下财务部有哪些在用资产"
"查 GB-00040 这台资产的操作记录"
"最近有哪些资产申购单？"
"我有哪些待办审批？"
```

---

## 技能详情

### gongbei-asset — 资产档案

**安装**
```bash
npx skills add https://github.com/chensanpi/gongbei-skills.git --skill gongbei-asset
```

| 能力 | 说明 |
|---|---|
| 查询资产卡片 ✅ | 分页 + 排序 + 多条件筛选（编码/分类/入库时间/使用人/管理员等）+ 特殊参数（`keyword` 全局模糊检索、`statusName` 资产状态、`extFields.text009` 资产名称、`extFields.text001` 财务属性），返回完整字段 |
| 查询资产操作记录 ✅ | 分页查询资产操作履历（操作人/类型/变更内容/关联单据），按资产 ID 过滤 |
| 资产状态列表 ✅ | 全部状态枚举（10 空闲/20 在用/30 借用/40 已处置/50 已报失/流程中状态等），卡片查询 `statusName` 筛选取值来源 |

> 本技能**只读**：仅提供以上三个查询接口；资产详情可由卡片查询按 `id`/`code.keyword` 精确过滤获得；新增/修改/删除资产、资产分类等请引导用户在公贝系统中处理。

> 示例："帮我查一下研发部有多少台在用笔记本" → Agent 调资产卡片查询，按分类/状态/使用部门过滤后返回统计。

### gongbei-approval — 审批&待办中心

**安装**
```bash
npx skills add https://github.com/chensanpi/gongbei-skills.git --skill gongbei-approval
```

| 能力 | 说明 |
|---|---|
| 审批实例列表 | 分页 + 按发起人/部门/单据类型/编码/状态/创建时间筛选，返回摘要与关联单据 |
| 用户审批待办 | 按人员查待办列表（含待办数量统计） |

> 本技能**只读**：仅提供审批实例列表与用户待办查询；审批详情、已办、抄送、效率诊断及同意/驳回/撤销等操作请引导用户在公贝系统中处理。

> 示例："我的待办有哪些？" → Agent 按当前用户查待办列表并汇总；"最近有哪些审批？" → Agent 查审批实例列表并按状态汇总。

### gongbei-requisition — 资产申购单

**安装**
```bash
npx skills add https://github.com/chensanpi/gongbei-skills.git --skill gongbei-requisition
```

| 能力 | 说明 |
|---|---|
| 查询资产申购单 ✅ | 分页查询（formType=40），通用筛选（编码/状态/发起人/部门/关联单号/审批实例）+ 申购单专属筛选（申请时间/采购总数量/采购总金额/待入库总数量），明细含资产快照（分类/位置/管理员/品牌/型号/序列号） |

> 本技能**只读**：仅提供申购单查询；新增/删除/更新申购单及申购统计请引导用户在公贝系统中处理。

> 示例："查一下最近 3 个月的资产申购单" → Agent 按 formType=40 + orderFields.operateTime 时间范围查询并汇总状态。

---

## 项目结构

```
tests/
├── test_gb_helper.sh         # 框架级冒烟测试（离线）
└── mock_token_test.sh        # Token 链路离线验证（mock curl）
.agents/skills/
├── gongbei-asset/           # 资产档案
│   ├── SKILL.md             # 技能主文件（触发条件 + 策略指南 + 工作流程）
│   ├── scripts/
│   │   └── gb_helper.sh     # 公贝开放平台辅助工具（配置 + Token）
│   └── references/
│       └── api.md           # API 参考（鉴权/通用约定已确认，业务接口待补齐）
├── gongbei-approval/        # 审批&待办中心
└── gongbei-requisition/     # 资产申购单
```

## 贡献

欢迎 PR。每个技能存放在 `.agents/skills/<技能名>/` 目录下，遵循标准技能结构。API 补齐的检查项见 [notes/todo.md](notes/todo.md)，开发规范见 `AGENTS.md`。

## 相关链接

- [公贝资产开放平台文档](https://doc.gongbeiyun.com/web/#/5/640)
- [公贝资产官网](https://www.gongbeiyun.com)
- [anthropics/skills 规范](https://github.com/anthropics/skills)
- [dingtalk-skills（本项目风格参考）](https://github.com/breath57/dingtalk-skills)

## 许可证

MIT
