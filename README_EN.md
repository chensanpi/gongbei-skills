# gongbei-skills

[中文](README.md) | English

---

Let your AI Agent operate the **Gongbei Asset Open Platform (公贝资产开放平台)** directly — no manual API calls, no token management, just conversation.

Built on the [Anthropic skills spec](https://github.com/anthropics/skills), with **zero dependencies — only `curl`** for HTTP requests, no Python, no SDK, nothing extra to install. After installation your agent automatically understands when to call Gongbei APIs, which endpoint to use, and how to fill in the parameters — including **automatic config management** and error handling.

> 📌 **Implemented capabilities**: Built on the official docs (https://doc.gongbeiyun.com/web/#/5/640), the **auth flow and common conventions** are implemented: API_HOST (unified `https://d-oapi.gongbeiyun.com`), `getAppToken` → `appToken` (sent as `?appToken=` query param), unified response envelope, form-field structure query, and custom field (`extFields`) assignment rules. The skill library provides three modules: **Approval & Todo Center (gongbei-approval, read-only)**: approval instance list, user approval todo list; **Asset registry (gongbei-asset, read-only)**: asset card pagination query, asset status list, asset operation log; **Asset requisition (gongbei-requisition, read-only)**: requisition document pagination query (formType=40, filter by apply time / total purchase qty / total purchase amount / pending-storage qty). Other business modules (procurement/transfer/stocktake/repair/scrap/reports/master data, etc.) are not yet in the skill library — they will be added on demand as their endpoints are published.

## Why use this

- **Talk, don't code**: "Show me the in-use assets of the Finance department" → Agent handles it end-to-end, no API knowledge required
- **Zero dependencies**: Only `curl` for HTTP requests — no Python, no SDK, no extra languages to install
- **Configure once, use everywhere**: On first run, the agent collects appKey/appSecret in a single prompt, saves to `~/.gongbei-skills/config`, and reuses across all skills automatically

## Long-term Goals

This project pursues two parallel long-term objectives:

**1. Always only `curl`**
No SDKs, no runtimes, no third-party dependencies — ever. If the system has `curl`, the skill runs. This guarantees maximum portability and zero-install operation in any agent environment.

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

1. Create an app on the [Gongbei Asset Open Platform](https://doc.gongbeiyun.com/web/#/5/640): right-click the homepage logo → open the "开放平台" tab → create an app → get its `appKey` and `appSecret`
2. API_HOST is fixed at `https://d-oapi.gongbeiyun.com` — no configuration needed (overridable via the `GONGBEI_BASE_URL` env var)
3. Prepare your app's `appKey` and `appSecret` — the agent will walk you through the setup

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

On first run, the agent checks `~/.gongbei-skills/config`, asks for anything missing in one go, and saves it. Then:

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
| Query asset cards ✅ | Paginated + sorting + multi-condition filters (code/name/category/storage time/status/user/admin, etc.), full fields; `status` excludes disposed(40) by default |
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
