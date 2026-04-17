# Contributing to anyGoShell

感谢你考虑为 anyGoShell 做贡献！

## 如何贡献

### 报告 Bug

1. 在 [Issues](https://github.com/tom-hanks/anyGoShell/issues) 页面搜索是否已有类似问题
2. 如果没有，创建新的 Bug Report，包含：
   - macOS 版本
   - 终端应用及版本
   - 问题复现步骤
   - 预期行为 vs 实际行为
   - 截图（如有）

### 提交功能建议

1. 在 Issues 页面搜索是否已有类似建议
2. 创建 Feature Request，描述：
   - 功能用途
   - 使用场景
   - 可能的实现思路

### 提交代码

1. Fork 本仓库
2. 创建功能分支：`git checkout -b feature/your-feature-name`
3. 确保代码通过编译：`make build`
4. 提交 PR，关联相关 Issue

## 开发环境

- macOS Sequoia 15.0+
- Xcode 16+
- Swift 6.0+

## 代码规范

- Swift 6 严格并发检查
- 使用 SwiftUI 构建 UI
- 本地化字符串使用 `L10n.swift` 管理
- 保持函数简短，单一职责

## 项目结构

```
anyGoShell/
├── Sources/           # 主代码
│   ├── main.swift     # 入口
│   ├── Views.swift    # SwiftUI 界面
│   ├── TerminalManager.swift
│   ├── FinderManager.swift
│   └── L10n.swift     # 本地化
├── Resources/         # 资源文件
└── scripts/           # 开发脚本（图标生成等）
```
