# gongbei-skills

[中文](README.md) | English

---

Let your AI Agent operate the **Gongbei Asset Open Platform (公贝资产开放平台)** directly — no manual API calls, no token management, just conversation.

Built on the [Anthropic skills spec](https://github.com/anthropics/skills). Skills call Gongbei through the internal `hun-cli` gateway; they do not assemble HTTP requests or handle credentials. Authentication, token refresh, data permissions, and error codes are owned by hun.

> **Implemented capabilities**: The library provides three read-only modules: approval and todo, asset registry, and asset requisitions. Each skill handles intent routing, parameter extraction and validation, hun action selection, and response organization. Action and field details live in each skill's `references/api.md`.

## Why use this

- **Talk, don't code**: "Show me the in-use assets of the Finance department" → Agent handles it end-to-end, no API knowledge required
- **Unified gateway**: Every business call uses `hun post gongbei <action>`
- **Managed authorization**: Run `hun auth login`; skills never collect or store secrets

## Long-term Goals

This project pursues two parallel long-term objectives:

**1. Always use hun**
Skills do not implement authentication, HTTP requests, or token management. All network access uses hun's gateway and authorization chain.

**2. Push token cost to the absolute minimum**
Every task execution loads skill files into the agent's context window — **the skill file itself is a cost**. Our goal isn't just correctness; it's writing `SKILL.md` and `references/api.md` as concisely as possible while maintaining full accuracy.

## Skills Overview

| Skill | Status | Description |
|---|---|---|
| [gongbei-asset](#gongbei-asset--asset-registry) | ✅ Live | Asset registry (read-only): asset card query, status list, operation log |
| [gongbei-approval](#gongbei-approval--approval--todo-center) | ✅ Live | Approval & Todo Center (read-only): approval instance list, user todo list |
| [gongbei-requisition](#gongbei-requisition--asset-requisition) | ✅ Live | Asset requisition (read-only): requisition document pagination query (formType=40) |

## Quick Start

### Prerequisites

1. Install `hun` and make sure it is available on `PATH`.
2. Run `hun auth login`, then verify with `hun auth status`.
3. Confirm that the hun gateway has registered the `gongbei` app and the actions listed in the skill references.

### Install a Skill

Install uniformly with `npx skills` — works with Cursor / Claude / Copilot / 🦞 OpenClaw / Hermes and almost any Agent:

```bash
# Install a single skill
npx skills add https://github.com/chensanpi/gongbei-skills.git --skill gongbei-asset

# Install all skills at once (auto-installs to every supported agent platform, no need to list them)
npx skills add https://github.com/chensanpi/gongbei-skills.git --all

# Install all skills to a specific agent only (example: Claude Code only)
npx skills add https://github.com/chensanpi/gongbei-skills.git --skill '*' -a claude-code
```

> The repository is hosted on GitHub (https://github.com/chensanpi/gongbei-skills). One-click install from ClawHub / skills.sh once published.

### Just Talk

On first run, the agent checks `~/.gongbei-skills/config` (including `GONGBEI_APP_TYPE`), asks for anything missing in one go, and saves it. Then:

```
"Show me the in-use assets of the Finance department"
"Show the operation log of asset GB-00040"
"Any recent asset requisitions?"
"What approval todos do I have?"
```

---

## Skill Details

### gongbei-asset — Asset Registry

**Install**
```bash
npx skills add https://github.com/chensanpi/gongbei-skills.git --skill gongbei-asset
```

| Capability | Description |
|---|---|
| Query asset cards ✅ | Paginated + sorting + multi-condition filters (code/category/storage time/user/admin, etc.) + special params (`keyword` global fuzzy search, `statusName` asset status, `extFields.text009` asset name, `extFields.text001` financial attribute), full fields |
| Query asset operation log ✅ | Paginated operation history (operator/type/change content/linked document), filter by asset ID |
| Asset status list ✅ | Full status enum (10 idle / 20 in use / 30 borrowed / 40 disposed / 50 reported lost / in-process states, etc.); source of `status` filter values in card query |

> This skill is **read-only**: only the three query interfaces above; asset detail is available by filtering the card query on `id`/`code.keyword`; creating/updating/deleting assets and asset categories are handled in the Gongbei console.

> Example: "How many in-use laptops does the R&D department have?" → Agent calls the asset card query, filters by category/status/department, returns stats.

### gongbei-approval — Approval & Todo Center

**Install**
```bash
npx skills add https://github.com/chensanpi/gongbei-skills.git --skill gongbei-approval
```

| Capability | Description |
|---|---|
| Approval instance list | Paginated, filter by initiator/dept/document type/code/status/create time, with summary & linked document |
| User todo list | Per-user approval todo list (with todo count) |

> This skill is **read-only**: only approval instance list and user todo queries; approval details, done/CC lists, efficiency stats and any write operations are handled in the Gongbei console.

> Example: "What are my todos?" → Agent queries the todo list for the current user; "What approvals are there recently?" → Agent queries the instance list and summarizes by status.

### gongbei-requisition — Asset Requisition

**Install**
```bash
npx skills add https://github.com/chensanpi/gongbei-skills.git --skill gongbei-requisition
```

| Capability | Description |
|---|---|
| Query asset requisitions ✅ | Paginated query (formType=40), common filters (code/status/initiator/dept/linked order/approval instance) + requisition-specific filters (apply time / total purchase qty / total purchase amount / pending-storage qty); line items carry asset snapshots (category/location/admin/brand/model/SN) |

> This skill is **read-only**: only requisition document queries; creating/updating/deleting requisitions and requisition statistics are handled in the Gongbei console.

> Example: "Show me asset requisitions from the last 3 months" → Agent queries with formType=40 + `orderFields.operateTime` range and summarizes statuses.

---

## Project Structure

```
tests/
├── test_gb_helper.sh         # Offline framework smoke test
└── mock_token_test.sh        # Offline token-flow test (mock curl)
.agents/skills/
├── gongbei-asset/           # Asset registry
│   ├── SKILL.md             # Skill main file (triggers + strategy + workflow)
│   ├── scripts/
│   │   └── gb_helper.sh     # Gongbei open platform helper (config + token)
│   └── references/
│       └── api.md           # API reference (auth/common conventions confirmed; business endpoints pending)
├── gongbei-approval/        # Approval & Todo Center
└── gongbei-requisition/     # Asset requisition
```

## Contributing

PRs welcome. Each skill lives in `.agents/skills/<skill-name>/` following the standard skill structure. API checklist: [notes/todo.md](notes/todo.md). Development conventions: `AGENTS.md`.

## Related Links

- [Gongbei Asset Open Platform Docs](https://doc.gongbeiyun.com/web/#/5/640)
- [Gongbei Asset Website](https://www.gongbeiyun.com)
- [Anthropic skills spec](https://github.com/anthropics/skills)
- [dingtalk-skills (style reference)](https://github.com/breath57/dingtalk-skills)

## License

MIT
