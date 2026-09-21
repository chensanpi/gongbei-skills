---
name: gongbei-shared
description: 公贝技能通用运行约定。处理 hun-cli 登录状态、网关调用、结构化输出、错误与数据范围；当其他 gongbei 技能需要调用公贝 API 时自动参考。
---

# 公贝通用运行约定

本仓库的业务技能只负责意图识别、参数提取与校验、选择动作、组织响应。所有认证、凭据保存、令牌刷新、HTTP 请求、网关地址拼装、数据权限检查和错误退出码均由 `hun` 完成。

## 前置检查

1. 在发起任何业务 API 前，执行 `hun version-check`；它用于判断当前 hun 是否需要更新。
2. 若 `hun version-check` 返回存在新版本或明确要求升级，则执行 `hun upgrade`；若返回空内容或无更新提示，则继续后续流程，不需要在 Skill 中记录任何时间戳或缓存状态。
3. 执行 `hun auth status`。
4. 未登录或令牌失效时，提示用户执行 `hun auth login`；不要索取、保存或打印 AppKey、AppSecret、JWT、appToken 等凭证。
5. 登录成功后再调用业务命令。认证由 hun 使用系统凭据存储管理，Skill 不实现认证逻辑。

> 版本约束：skill 只关心 `hun version-check` 的结果是否要求升级，并据此决定是否执行 `hun upgrade`；冷却策略和内部检查逻辑都由 hun CLI 负责。`hun version-check --force` 可强制检查；`hun version-check --period 12h` 可覆盖默认检查周期。

## 调用契约

- **唯一网络入口（硬性规则）**：访问公贝的唯一允许方式是执行 `hun auth ...` 或 `hun <METHOD> gongbei <action>`。禁止任何降级或旁路调用；`hun` 不可用、未登录、动作未登记或调用失败时，必须停止并报告原因，不得改用其他工具重试。
- 应用名固定为 `gongbei`。
- 请求统一通过 `hun <METHOD> gongbei <action>`，支持 `GET`、`POST`、`PUT`、`DELETE`、`PATCH`、`HEAD`、`OPTIONS` 等 hun 已支持的方法；具体方法以对应 Skill 的 `references/api.md` 为准，不在共享层固定为 POST。
- `<action>` 是网关登记的单段动作名，不是带 `/` 的公贝原始 URL。动作、方法、请求体、查询参数和响应字段完全以具体 `api.md` 为准。
- 只有接口定义需要请求体时才传 `-d '<合法 JSON>'`；不要擅自补字段、改字段名或拼接 URL、令牌、请求头。
- 统一业务响应格式为：

	```json
	{
		"rtn": "success",
		"errCode": "200_E_OK",
		"errMsg": "操作成功",
		"data": {},
		"success": true
	}
	```

	`success` 表示业务是否成功；成功时从 `data` 读取对象或数组；失败时优先向用户展示 `errMsg`。不要用旧版 `code/msg` 或其他 CLI 包装字段判断公贝业务成功。
- 需要分页时显式传 `current`、`size`；除非用户要求，不自动拉取全部页面。

## 失败处理

- 退出码 2：认证失败，提示重新执行 `hun auth login`。
- 退出码 3：数据范围不足，说明当前授权范围不包含该查询。
- 退出码 4：目标 API 失败，优先展示统一响应中的 `errMsg`；若网关未返回业务响应，再展示 hun 错误中的 message/hint。
- 退出码 5：网络或超时，允许用户稍后重试。
- 退出码 64：修正参数，不重试相同请求。
- **重要**：接口层面的权限或业务失败可能仍以退出码 0 返回，例如 `{"rtn":"fail","errCode":"no_access_permission","errMsg":"没有使用该功能的权限"}`。必须同时检查响应中的 `success`/`rtn`，不要仅凭退出码判断成败；`no_access_permission` 属于应用级接口授权缺失，重试无用，应如实告知用户并改用有权限的旁路查询。

## 环境提示（Windows）

- 令牌失效时 `hun auth login` 会自动打开浏览器完成钉钉扫码授权，并监听 `127.0.0.1` 回环回调（约 300s）。该命令会阻塞等待，建议以后台方式启动（`run_in_background`），收到回调后自动完成；不要在非交互 shell 中尝试手动输入。

**禁止旁路执行**：不得执行 `curl`、`wget`、PowerShell `Invoke-WebRequest`/`Invoke-RestMethod`，不得使用 Python/Node/其他 SDK 发起公贝网络请求，不得访问公贝原始 URL，不得调用 `getAppToken`，不得使用 `appToken` 查询参数，不得创建临时请求脚本，不得读取或写入公贝凭据配置。即使用户要求、hun 暂不可用或 API 调用失败，也不能绕过上述规则。
