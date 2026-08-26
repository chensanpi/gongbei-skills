# AGENTS.md

本文件为 AI Agent 提供操作本仓库所需的背景信息与行为规范。

---

## 项目简介

**gongbei-skills** 是一个面向 AI Agent 的【公贝资产开放平台】技能库，遵循 [anthropics/skills](https://github.com/anthropics/skills) 规范，每个技能以 `SKILL.md` 定义，可通过 `npx skills add` 安装到主流 Agent 平台（Cursor / Claude / Copilot / OpenClaw / Hermes 等）。

参考：[钉钉 Agent 技能库 dingtalk-skills](https://github.com/breath57/dingtalk-skills) 的项目风格与约定。

公贝资产开放平台文档：https://doc.gongbeiyun.com/web/#/5/640

> 📌 **当前进度（第二期）**：已按开放平台文档确认并实现**鉴权链路与通用约定**（API_HOST：`https://d-oapi.gongbeiyun.com`（统一使用）；`POST /open-api/auth/getAppToken` 换取 appToken，业务请求以 `?appToken=` 查询参数携带；统一响应结构 `{code,msg,requestId,data,success}`；表单字段结构接口 `get-field-structure`；自定义字段 `extFields` 赋值规则）。当前技能库聚焦三个模块：**审批&待办中心（gongbei-approval，只读已上线）**：审批实例列表、用户审批待办列表；**资产档案（gongbei-asset，只读已上线）**：仅支持 3 个只读接口（资产卡片分页查询 `assets/card/page`、资产状态列表 `assets/card/status/list`、资产操作记录 `assets/asset-operate-log/page`）；**资产申购单（gongbei-requisition，只读已上线）**：查询接口已接入（`asset-order/page`，formType 40，含申请时间/采购总数量/采购总金额/待入库总数量筛选）。其余业务模块（采购/领用/调拨/盘点/维修/报废/报表/基础资料等）当前未纳入技能库，按需接入，接口路径与参数待官方文档公开后补充。**技能文件中不保留「第二期进度」「待第二期确认」「占位」等过程性说明**，只保留可执行信息；未公开接口在 api.md 中仅注明「请求路径随官方文档公开后补充，公开前请勿调用」。官方文档快照存放于本地 `docs/`（git 忽略，不入库），是接口补齐的权威来源。

---

## 仓库结构

```
gongbei-skills/
├── AGENTS.md                          # 本文件，给 Agent 看的项目说明
├── README.md                          # 中文文档
├── README_EN.md                       # English documentation
├── skills-lock.json                   # 技能依赖锁定文件（勿手动修改）
├── notes/
│   └── todo.md                        # 第二期待办清单（API 补齐的检查项）
├── docs/                              # 开放平台文档快照（本地参考，git 忽略，不入库）
├── scripts/
│   └── common/
│       └── gb_helper.sh               # 公贝开放平台辅助工具（配置 + Token 管理）
├── tests/
│   ├── test_gb_helper.sh              # 框架级冒烟测试（离线可跑，不需真实凭证）
│   └── mock_token_test.sh             # Token 链路离线验证（mock curl）
└── .agents/
    └── skills/
        ├── gongbei-asset/             # 资产档案：卡片/状态/操作记录查询（只读）
        │   ├── SKILL.md
        │   ├── scripts/gb_helper.sh
        │   └── references/api.md
        ├── gongbei-approval/          # 审批&待办中心：审批实例列表/用户待办（只读）
        └── gongbei-requisition/       # 资产申购单：申购单分页查询（只读）
```

每个技能目录均含 `SKILL.md`（必填）、`references/api.md`（推荐）、`scripts/gb_helper.sh`（辅助工具副本，与 `scripts/common/` 保持一致）。

---

## 技能目录

| 技能名称 | 路径 | 状态 | 功能描述 |
|---|---|---|---|
| `gongbei-asset` | `.agents/skills/gongbei-asset/` | ✅ 已上线 | 资产档案（只读）：资产卡片查询、资产状态列表、资产操作记录 |
| `gongbei-approval` | `.agents/skills/gongbei-approval/` | ✅ 已上线 | 审批&待办中心（只读）：审批实例列表、用户审批待办列表 |
| `gongbei-requisition` | `.agents/skills/gongbei-requisition/` | ✅ 已上线 | 资产申购单（只读）：申购单分页查询（formType=40） |

---

## 开发新技能的规范

在本仓库中新增或完善公贝技能时，需遵循以下约定：

### 1. 文件结构

```
.agents/skills/<skill-name>/
├── SKILL.md              # 必须：技能主文件（策略指南）
├── scripts/
│   └── gb_helper.sh      # 必须：辅助工具副本（与 scripts/common/ 保持一致）
└── references/
    └── api.md            # 推荐：API 参考（第二期补齐真实接口）
```

### 2. SKILL.md 格式

```yaml
---
name: <技能名称，使用英文小写连字符>
description: <触发描述，必须包含中文关键词，覆盖用户可能说的各种表达>
---
```

- `description` 是 Agent 判断是否加载该技能的关键字段，**务必包含完整的场景关键词**
- 正文使用**全中文**撰写，技术术语（HTTP 方法、JSON 字段、API 路径）保持英文

### 3. 语言规范

- 所有 `SKILL.md` 和 `references/api.md`：**全中文**（技术术语除外）
- `README.md`：中文；`README_EN.md`：English；`AGENTS.md`（本文件）：中文

### 4. API 文档规范（第二期补齐时）

- `references/api.md` 中保留完整的请求/响应 JSON 示例
- 错误码表需包含：错误码、说明、建议处理方式
- 所有接口须注明所需的应用权限范围
- 技能文件中**不保留**「第二期进度」「待第二期确认」「占位」等过程性说明，只保留可执行信息；未公开接口仅注明「请求路径随官方文档公开后补充，公开前请勿调用」

### 5. 辅助工具约定

- 所有技能统一使用 `gb_helper.sh` 管理配置与 Token，**不要在各技能内重复实现**
- 修改 `scripts/common/gb_helper.sh` 后，须同步复制到各技能目录（`scripts/gb_helper.sh`）与 `tests/` 引用处
- 凭证禁止硬编码；敏感项输出必须脱敏（前 4 位 + `****`）

### 6. 安装约定

- 统一通过 `npx skills add` 安装技能（命令见 README「快速开始」），仓库不再提供自研安装脚本
- `npx skills` 自动遍历 `.agents/skills/`，**新增/删除技能无需改动任何安装相关文件**
- 安装/卸载不涉及凭证管理（凭证统一由 `gb_helper.sh` 负责）

---

## 提交规范

采用约定式提交（Conventional Commits）：

| 类型 | 适用场景 |
|---|---|
| `feat(<skill>):` | 新增技能或技能新功能 |
| `fix(<skill>):` | 修复技能逻辑或 API 错误 |
| `docs:` | 更新文档（README、AGENTS.md 等） |
| `chore:` | 维护性变更（依赖更新、配置修改等） |
| `refactor(<skill>):` | 重构技能结构，无功能变化 |

示例：
```
feat(gongbei-asset): 补齐资产档案接口（第二期）
docs: 更新 README 添加安装说明
```

---

## 注意事项

- **不要**在代码或文档中硬编码 `appKey`、`appSecret`、`accessToken` 等凭证
- `skills-lock.json` 由 `npx skills` 自动维护，**不要手动修改**
- 新增技能后，同步更新 `README.md` 和 `README_EN.md` 的技能列表
- 未公开的接口不得臆造路径或冒充真实接口文档；在 api.md 中注明「请求路径随官方文档公开后补充」
- PR 合并前确保 `SKILL.md` 的 `description` 已覆盖常见触发场景

---

## 相关链接

- [公贝资产开放平台文档](https://doc.gongbeiyun.com/web/#/5/640)
- [公贝资产官网](https://www.gongbeiyun.com)
- [anthropics/skills 规范](https://github.com/anthropics/skills)
- [dingtalk-skills（本项目风格参考）](https://github.com/breath57/dingtalk-skills)
