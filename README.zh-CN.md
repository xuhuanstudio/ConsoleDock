# ConsoleDock

面向 iOS 测试场景的 App 内调试日志面板。

ConsoleDock 是一个早期阶段的 iOS debug SDK，目标是让测试人员在真机或模拟器上直接查看 App 日志，减少为了看基础日志而实时连接 Xcode 的依赖。

> 说明：英文 [README](README.md)、DocC 和 `docs/` 是项目的权威文档。本文是中文概览，方便快速理解项目定位和接入方式。

## 当前状态

ConsoleDock `v0.3.1` 是当前 source-first Swift Package Manager 公开预览版本，包含：

- Swift Package Manager package；
- Objective-C/C 兼容的 `ConsoleDockCore`；
- Swift facade `ConsoleDock`；
- stdout/stderr 文件描述符捕获、透传和恢复；
- 带 session 内稳定 ID 和 partial/redacted/truncated 标记的本地内存日志存储；
- runtime diagnostics，用于查看运行状态、capture 配置和当前内存 store 计数；
- Debug Actions，用于注册 App 主动提供的本地测试快捷动作；
- 日志详情页、单条复制，以及 visible/all 日志分享；
- 默认敏感字段脱敏；
- UIKit 浮动按钮和日志面板；
- Swift 和 Objective-C 示例 App；
- Release 默认禁用保护；
- DocC、CI、release validation 和开源治理文档。

## 能力边界

ConsoleDock 不能被描述成 Xcode Console 或 Apple unified logging 的完整替代品。

ConsoleDock 可以覆盖：

- Swift `print`；
- C `printf` / `fprintf`；
- stdout / stderr；
- 很多通过进程 stderr 输出的 `NSLog`；
- 通过 ConsoleDock 显式 API 写入的日志。

ConsoleDock 不能承诺完整、稳定、实时、零侵入捕获：

- Swift `Logger`；
- `os_log`；
- Apple unified logging；
- 其他 App 或系统进程日志；
- 断点、LLDB 表达式、sanitizer 诊断等调试器能力。

如果需要可靠完整的 App 内日志展示，推荐使用 ConsoleDock 的显式 API，或者在已有 logger 中增加 sink/appender 转发。

## Swift 快速开始

通过 Swift Package Manager 添加公开仓库地址，并选择 GitHub Releases 中最新的 release tag。`v0.3.1` 已包含 Debug Actions、日志详情、visible/all 分享、runtime diagnostics 和当前 release validation 加固：

```text
https://github.com/xuhuanstudio/ConsoleDock.git
```

```swift
import ConsoleDock

ConsoleDock.start()

ConsoleDock.info("Login succeeded")
print("Visible through stdout capture")
```

Debug 构建下，默认配置会启用 stdout/stderr 捕获，安装浮动 `CD` 按钮，进行基础敏感字段脱敏，并把日志保存在本地内存中。

## 运行诊断

Runtime diagnostics 从 `v0.2.0` 开始属于已发布能力。

接入时可以读取 diagnostics，确认 ConsoleDock 是否正在运行、stdout/stderr capture 是否启用、当前内存中有多少条日志，以及 redacted/truncated/partial 计数：

```swift
let diagnostics = ConsoleDock.diagnostics
print(diagnostics.isRunning)
print(diagnostics.entryCount)
```

```objc
CDKDiagnostics *diagnostics = [CDKConsoleDock diagnostics];
NSLog(@"ConsoleDock running: %@", diagnostics.isRunning ? @"YES" : @"NO");
NSLog(@"Stored entries: %lu", (unsigned long)diagnostics.entryCount);
```

diagnostics 只反映 ConsoleDock 本地运行状态和当前有界内存 store，不代表已经完整捕获 Swift `Logger`、`os_log` 或 Apple unified logging。

如果你要自己做调试面板，可以观察 `ConsoleDock.entriesDidChangeNotification` 刷新日志列表，观察 `ConsoleDock.diagnosticsDidChangeNotification` 刷新运行状态、capture 配置和 store 计数。通知会在改变 ConsoleDock 状态的线程发出，UIKit 更新需要切回主线程。

## Debug Actions

Debug Actions 从 `v0.3.0` 开始属于已发布能力。App 可以主动注册本地测试快捷动作，让测试人员在 ConsoleDock 面板里触发，例如进入某个测试页面、写入模拟错误日志、清理本地调试数据或记录 diagnostics。

```swift
ConsoleDock.registerAction(
    id: "open.checkout",
    title: "Open Checkout",
    group: "Navigation"
) {
    AppRouter.shared.openCheckout()
}
```

`id` 和 `title` 应使用非空的稳定值。ConsoleDock 会清理首尾空白，并在规范化后的 `id` 重复注册时替换旧 action。

ConsoleDock 只展示和触发 App 注册的动作；它不会自动发现页面、接管路由、绕过业务权限、远程下发命令，也不是自动化测试平台。

## Objective-C 快速开始

```objc
@import ConsoleDock;
@import ConsoleDockCore;

CDKConfiguration *configuration = [CDKConfiguration defaultConfiguration];
CDKStartResult result = [CDKConsoleDockUIKit startWithConfiguration:configuration error:nil];

[CDKConsoleDock info:@"Login succeeded"];
```

旧 Objective-C 项目如果只需要核心捕获、存储和通知能力，可以直接使用 `ConsoleDockCore`。如果需要内置 UIKit 面板，则同时使用 `ConsoleDock`。

## Release 安全

Release 构建默认返回 disabled，不会启动 ConsoleDock。Release 中启用必须同时满足：

- 编译时定义 `CONSOLEDOCK_ENABLE_RELEASE`；
- 配置 `allowsReleaseBuilds = true`。

不要在 App Store 生产构建中启用 ConsoleDock。详见 [Release build safety](docs/release-build-safety.md)。

## 文档入口

- [English README](README.md)
- [Product brief](docs/product-brief.md)
- [Logging migration guide](docs/migration-existing-loggers.md)
- [Privacy and redaction](docs/privacy-and-redaction.md)
- [Release process](docs/release-process.md)
- [GitHub repository setup](docs/github-repository-setup.md)
- [Roadmap](docs/roadmap.md)

## 本地验证

```sh
scripts/validate-release.sh
```

该脚本会先确认工作区干净，再验证 SwiftPM manifest、package identity、Swift Package Index 元数据、Objective-C API surface、Swift API surface、UI accessibility identifiers、sample app 文档和自动化、Swift 格式、构建、测试、Release safety gates、文档链接、开源治理元数据、分发文档和产物、公开发布内容审计、DocC、iOS package build、Swift/Objective-C 示例 App 构建、source archive 生成、source archive 内容和 source archive 独立构建/测试。GitHub workflow 会设置 `CONSOLEDOCK_RUN_UI_SMOKE=1`，因此 CI 会运行 Swift 和 Objective-C 示例 App 的 iOS Simulator UI smoke test；本地需要完整模拟器 smoke 路径时也可以设置同一个环境变量。

## 分发策略

当前唯一支持的公开分发渠道：

1. Swift Package Manager。

CocoaPods 和 XCFramework 不是当前主动发布目标。只有当真实旧项目或二进制分发需求证明 SPM 不够用时，才会重新评估。

更详细的分发策略见 [Distribution strategy](docs/distribution-strategy.md)。

仓库包含 Swift Package Index 元数据。PackageList 条目已通过 [SwiftPackageIndex/PackageList#14098](https://github.com/SwiftPackageIndex/PackageList/pull/14098) 合并；Swift Package Index 完成索引后，托管 package 和 DocC 页面才会稳定可访问。

ConsoleDock 当前不包含 CocoaPods、XCFramework、网络面板、崩溃采集、默认持久化、远程上传或第三方 logger 适配器。
