# AGENTS.md

## 项目简介

`gongbei-skills` 是公贝资产开放平台的 Agent Skills 集合。技能遵循 Anthropic Skills 规范，面向支持 `.agents/skills/` 的 Agent 环境。

技能通过内部 `hun-cli` 企业 API 网关访问公贝。业务技能不得直接访问公贝域名，不得拼装 HTTP 请求，不得实现认证或令牌缓存。

## 当前技能

| 技能 | 能力 |
|---|---|
| `gongbei-shared` | hun 登录状态、调用格式、错误和响应处理的通用约定 |
| `gongbei-approval` | 审批实例列表、审批实例详情、用户审批待办列表，只读 |
| `gongbei-asset` | 资产卡片、资产状态、资产操作记录，只读 |
| `gongbei-asset-order` | 资产单据通用分页查询（入库/借用/归还/派发/退库/调拨/维修/处置/批量修改/领用申请/报修/退还）及关联单据编号查看，只读 |
| `gongbei-requisition` | 资产申购单分页查询（`formType=40`）、专属扩展字段 `extFields` 及其关联单据查看，只读 |

## 目录约定

```text
.agents/skills/<skill>/
├── SKILL.md
└── references/
    └── api.md
```

`SKILL.md` 只包含触发描述、意图路由、参数提取与校验、hun 动作选择、只读边界和响应组织方式。`references/api.md` 只记录 hun 的 app/action、JSON body、业务字段和响应映射。

不要在技能目录新增 `scripts/`、`gb_helper.sh`、curl 请求模板或认证配置文件。

## hun 调用规范

1. 在发起任何业务 API 前，先执行 `hun version-check`；其作用是检查当前 hun 是否需要升级。
2. 若 `hun version-check` 返回存在新版本或明确提示需要更新，则执行 `hun upgrade` 更新到最新版本；若返回空内容或不提示更新，则继续后续流程，不必自行维护任何时间戳或冷却逻辑。
3. 再执行 `hun auth status`；未认证时引导用户执行 `hun auth login`。
4. 业务请求统一使用 `hun post gongbei <action> -d '<JSON>'`。
5. `hun` 是访问公贝的唯一网络入口。`hun` 不可用、未登录、动作未登记或请求失败时必须停止，不得降级为任何其他 HTTP 客户端、脚本、SDK 或公贝原始 URL。
6. 不使用 `getAppToken`、`appToken` 查询参数、AppKey/AppSecret 或公贝原始 URL。
7. 读取 hun 的结构化输出和退出码：2 为认证失败，3 为数据权限不足，4 为目标 API 失败，5 为网络错误，64 为参数错误。
8. 业务动作必须是网关已登记的单段 action；动作名称和 body 以对应 `references/api.md` 为准。
9. 不要向用户展示 JWT、AppKey、AppSecret、appToken 或其他认证材料。

> 更新机制：技能只负责调用 `hun version-check` 和必要时 `hun upgrade`；版本检测、冷却与升级决策全部由 hun CLI 内部处理。`hun version-check --force` 可强制检查；`hun version-check --period 12h` 可覆盖默认检查周期。

禁止执行 `curl`、`wget`、PowerShell `Invoke-WebRequest`/`Invoke-RestMethod`，或使用 Python/Node/其他 SDK 直接访问公贝。即使 hun 暂不可用或调用失败，也不能绕过 hun。

## 业务边界

现有四个业务技能保持只读能力不变。审批已办、抄送、效率诊断及审批写操作不属于审批技能；资产写操作、单据写操作和申购单写操作均不属于当前技能范围。各技能的动作与字段以对应 `references/api.md` 为准，`formType` 一次只能传一个，不得为绕过权限或凑结果遍历单据类型。未接入模块不要臆造动作，明确告知用户范围。

## 文档与测试

更新动作、字段或路由时，同时更新对应 `SKILL.md` 与 `references/api.md`。本仓库不再维护公贝认证脚本测试；运行验证应使用 `hun auth status`，再调用一个已登记的只读动作。不要提交真实凭证、令牌或生产数据。

## 安装

统一使用 Skills CLI 安装，例如：

```bash
npx skills add <repository> --all
```

授权与配置由 hun 管理，不由安装脚本或 Skill 管理。
