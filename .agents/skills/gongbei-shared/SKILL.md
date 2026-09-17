---
name: gongbei-shared
description: 公贝技能通用运行约定。处理 hun-cli 登录状态、网关调用、结构化输出、错误与数据范围；当其他 gongbei 技能需要调用公贝 API 时自动参考。
---

# 公贝通用运行约定

本仓库的业务技能只负责意图识别、参数提取与校验、选择动作、组织响应。所有认证、凭据保存、令牌刷新、HTTP 请求、网关地址拼装、数据权限检查和错误退出码均由 `hun` 完成。

## 前置检查

1. 执行 `hun auth status`。
2. 未登录或令牌失效时，提示用户执行 `hun auth login`；不要索取、保存或打印 AppKey、AppSecret、JWT、appToken 等凭证。
3. 登录成功后再调用业务命令。认证由 hun 使用系统凭据存储管理，Skill 不实现认证逻辑。

## 调用契约

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

不要执行 `curl`，不要调用 `getAppToken`，不要使用 `appToken` 查询参数，不要创建临时请求脚本，不要读取或写入公贝凭据配置。
