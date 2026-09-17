# 测试说明

本项目为 MVP（第一期）框架版本，**暂无真实 API 可测**。当前提供两个**离线**测试：

| 测试 | 说明 | 运行方式 |
|---|---|---|
本仓库不再实现公贝认证或 HTTP 请求脚本。运行时验证由 `hun` 自身负责，技能层只需检查动作、请求体和响应组织契约。

建议的最小验证：

```powershell
hun auth status
hun post gongbei assetStatusList -d '{}'
```

未登录时先执行 `hun auth login`。第二条命令需要网关已登记 `gongbei/assetStatusList` 动作。

两者均不依赖真实凭证与网络（使用临时 config，测试结束自动清理）。

## 第二期集成测试约定

第二期 API 补齐后，参考 [dingtalk-skills](https://github.com/breath57/dingtalk-skills) 的测试结构补充集成测试：

```
tests/
├── .env.example          # 测试凭证模板（.env 不提交到 git）
├── test_gb_helper.sh     # 框架冒烟测试（离线）
├── mock_token_test.sh    # Token 链路离线验证（mock curl）
└── <skill-name>/         # 各技能集成测试（需真实凭证）
    └── test_<module>.py  # 或 test_<module>.sh
```

**要求：**
- 使用真实 API 调用（不 mock），验证接口实际可用
- 每个核心操作（增/删/改/查）均须有对应测试用例
- 测试 fixture 负责创建测试资源并在结束后自动清理，不留脏数据
- 新增或修改技能后，须确保测试全部通过再提交
