# ConsoleDock

面向 iOS 测试场景的 App 内调试日志面板。

ConsoleDock 是一个早期阶段的 iOS debug SDK，目标是让测试人员在真机或模拟器上直接查看 App 日志，减少为了看基础日志而实时连接 Xcode 的依赖。

> 说明：英文 [README](README.md)、DocC 和 `docs/` 是项目的权威文档。本文是中文概览，方便快速理解项目定位和接入方式。

## 当前状态

ConsoleDock `v0.14.0` 是当前 source-first Swift Package Manager 公开预览版本，包含：

- Swift Package Manager package；
- Objective-C/C 兼容的 `ConsoleDockCore`；
- Swift facade `ConsoleDock`；
- stdout/stderr 文件描述符捕获、透传和恢复；
- `ConsoleDock.LogForwarder` 和 `CDKLogForwarder`，用于在已有 logger 的 sink/appender 中低改动转发日志；
- 带 session 内稳定 ID 和 partial/redacted/truncated 标记的本地内存日志存储；
- session metadata 和手动 marker，用于标记一次本地测试复现过程；
- runtime diagnostics，用于查看运行状态、capture 配置和当前内存 store 计数；
- Integration Diagnosis 和 Context 页里的 ConsoleDock Health，用于排查接入后为什么没有看到预期日志、action、context 或 archive；
- Debug Actions，用于注册 App 主动提供的本地测试快捷动作，并支持 disabled/destructive 元数据、本地搜索、小型参数表单、当前 session 执行历史和 session-only 最近参数值复用；
- App Context，用于让 App 提供本地上下文快照，并显示在内置 Context 页和 report 中；
- 日志详情页、单条复制、Logs 本地结构化查询、Logs Jump、Session Timeline、reproduction timeline，以及 visible/all/issue report 分享；
- `Copy Issue Report` 和公开的 issue report 文本 API；
- Local Session Archive，用于显式保存、查看、分享、删除有界的本地 issue-report 快照；
- Support Report，用于 App 自己的反馈/客服入口按需生成最近 5/10/30/60 分钟或指定时间段的本地报告；
- 默认敏感字段脱敏；
- 可配置、可运行时隐藏/显示的 UIKit 浮动按钮和日志面板；
- Swift 和 Objective-C 示例 App；
- 当前 iOS Simulator 截图、文档图片校验、视觉 QA 指南和 segmented control 对比度修复；
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

如果需要可靠完整的 App 内日志展示，推荐使用 ConsoleDock 的显式 API，或者在已有 logger 中增加 sink/appender 转发。`v0.5.0` 开始提供的 `ConsoleDock.LogForwarder` / `CDKLogForwarder` 就是为这个迁移路径准备的轻量工具。

## 基础要求

- Swift Package Manager，Swift tools 5.9 或更高版本。
- iOS 12 或更高版本用于 SDK 和内置 UIKit 面板。
- macOS 12 或更高版本用于本地/CI 的 `swift build` 和 `swift test`；ConsoleDock 的产品目标仍然是 iOS App 调试。
- 内置浮动按钮和面板依赖 UIKit；核心日志/存储 API 仍可在非 UIKit 平台构建和测试。

## Swift 快速开始

通过 Swift Package Manager 添加公开仓库地址，并选择 GitHub Releases 中最新的 release tag。`v0.14.0` 已包含 Support Report、Integration Diagnosis、Context 页 ConsoleDock Health、Local Session Archive 显式保存/查看/删除、内置 Session Timeline、Logs 本地结构化查询、next/previous visible error jump、local Debug Action execution history、action form session-only 最近参数值复用、reproduction timeline issue reports、临时 `.txt` issue-report 分享、parameterized Debug Actions、App Context、可配置 floating trigger、Logs Jump、Actions 搜索、logger forwarders、Test Session Reports、manual markers、Debug Actions、日志详情、visible/all/issue-report 分享和复制、runtime diagnostics、当前 iOS Simulator 截图、文档图片校验、视觉 QA 指南、segmented control 对比度修复和当前 release validation 加固：

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

## 浮动入口配置

Floating trigger 配置从 `v0.6.0` 开始属于已发布能力。App 可以选择浮动 `CD` 按钮的初始角落，也可以在运行时隐藏或重新显示它：

```swift
let configuration = ConsoleDock.Configuration(
    floatingButtonPosition: .bottomLeading
)

ConsoleDock.start(configuration: configuration)
ConsoleDock.hideFloatingButton()
ConsoleDock.showFloatingButton()
```

```objc
CDKConfiguration *configuration = [CDKConfiguration defaultConfiguration];
configuration.floatingButtonPosition = CDKFloatingButtonPositionBottomLeading;

[CDKConsoleDockUIKit startWithConfiguration:configuration error:nil];
[CDKConsoleDockUIKit hideFloatingButton];
[CDKConsoleDockUIKit showFloatingButton];
```

如果项目想使用自己的调试入口，可以设置 `showsFloatingButton = false`，再通过 `ConsoleDock.showConsole()` / `[CDKConsoleDockUIKit showConsole]` 主动打开面板。

## 旧 logger 迁移

旧项目不需要把所有 `AppLog.info(...)` 调用点替换成 ConsoleDock。推荐做法是在原 logger 的集中出口加一个 forwarder：

```swift
private let consoleDockLog = ConsoleDock.LogForwarder(category: "AppLog", minimumLevel: .info)

func appLogInfo(_ message: String) {
    print(message)
    consoleDockLog.info(message)
}
```

```objc
CDKLogForwarder *forwarder = [[CDKLogForwarder alloc] initWithCategory:@"AppLog"
                                                           minimumLevel:CDKLogLevelInfo];
[forwarder info:@"Login succeeded"];
```

这不是自动读取 Swift `Logger` / `os_log`，而是把 App 自己已经决定要写出的日志同步转发到 ConsoleDock 的本地内存 store。

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

Integration Diagnosis 从 `v0.13.0` 开始属于已发布能力。接入后如果看不到预期日志，可以复制本地诊断文本：

```swift
let diagnosis = ConsoleDock.integrationDiagnosisText()
```

```objc
NSString *diagnosis = [CDKConsoleDockUIKit integrationDiagnosisText];
```

内置 Context 页会显示 `ConsoleDock Health`，并提供 `Copy Integration Diagnosis`。它会汇总 running 状态、stdout/stderr capture 配置、source/level 计数、redacted/truncated/partial 计数、Debug Actions、App Context、Local Session Archive 和本地建议。它仍然不会读取 Swift `Logger`、`os_log` 或 Apple unified logging。

如果你要自己做调试面板，可以观察 `ConsoleDock.entriesDidChangeNotification` 刷新日志列表，观察 `ConsoleDock.diagnosticsDidChangeNotification` 刷新运行状态、capture 配置和 store 计数。通知会在改变 ConsoleDock 状态的线程发出，UIKit 更新需要切回主线程。

## Logs 本地查询

Logs 本地结构化查询从 `v0.9.0` 开始属于已发布能力。内置 Logs 搜索框仍支持普通文本，也支持少量结构化 token，例如：

```text
level:error
level:warn
source:stderr
is:redacted
"checkout failed"
-heartbeat
```

支持的 key 是 `level:`、`source:` 和 `is:`。查询只影响本地 UI 可见列表，会和 source/level 控件叠加；它不会改变已存日志，不会持久化，也不是公开查询语言 API。

## Session Timeline

Session Timeline 从 `v0.10.0` 开始属于已发布能力。内置 `Timeline` 页会把当前 session 的 marker、本地 Debug Action 执行记录，以及当前保留的 error/fault 日志按时间聚合成一个本地排查视图。

Timeline 只是当前会话内的 UI 摘要：marker 和 error/fault 行可以打开日志详情，Debug Action 行可以打开 action 详情并复制执行元数据。它不会持久化历史、上传事件、自动发现页面或替代完整 Logs 列表。

## Debug Actions

Debug Actions 从 `v0.3.0` 开始属于已发布能力。App 可以主动注册本地测试快捷动作，让测试人员在 ConsoleDock 面板里触发，例如进入某个测试页面、写入模拟错误日志、清理本地调试数据或记录 diagnostics。

```swift
ConsoleDock.registerAction(
    id: "open.checkout",
    title: "Open Checkout",
    group: "Navigation",
    isEnabled: true,
    style: .normal
) {
    AppRouter.shared.openCheckout()
}
```

`id` 和 `title` 应使用非空的稳定值。ConsoleDock 会清理首尾空白，并在规范化后的 `id` 重复注册时替换旧 action。

ConsoleDock 只展示和触发 App 注册的动作；它不会自动发现页面、接管路由、绕过业务权限、远程下发命令，也不是自动化测试平台。`isEnabled` 可用于展示暂不可用动作，`.destructive` 可用于清理本地调试数据这类危险动作的 UI 提示。内置 Actions 页面可以按 `id`、标题、分组或详情做本地搜索，但搜索不会执行 action，也不会持久化。

Parameterized Debug Actions 和 App Context 从 `v0.7.0` 开始属于已发布能力。参数适合 order id、开关、数量、环境这类小型本地测试输入；ConsoleDock 不把它变成远程命令或自动化测试平台。

Local Debug Action execution history 和 reproduction timeline issue reports 从 `v0.8.0` 开始属于已发布能力。内置参数表单会在当前进程 session 内复用同一 action 最近一次通过校验的参数值，方便重复本地测试；这些值不会跨 App 重启持久化。`ConsoleDock.actionExecutionHistory` 可以读取当前 session 的 action 执行结果，`ConsoleDock.clearActionExecutionHistory()` 可以清空这份历史，但不会清空最近参数值。执行历史是有界的，明显像密钥的参数名和值会在摘要中基础脱敏。

```swift
ConsoleDock.registerAction(
    id: "open.order",
    title: "Open Order",
    group: "Scenario",
    parameters: [
        .string(id: "orderId", title: "Order ID", isRequired: true)
    ]
) { values in
    AppRouter.shared.openOrder(id: values.string("orderId") ?? "")
}
```

## 测试会话标记和问题报告

Test Session Reports 从 `v0.4.0` 开始属于已发布能力。测试人员或 Debug Action 可以在本地复现流程中插入 marker：

```swift
ConsoleDock.mark("Started checkout reproduction")

let metadata = ConsoleDock.sessionMetadata
print(metadata.sessionIdentifier)
```

```objc
[CDKConsoleDock mark:@"Started checkout reproduction"];

CDKSessionMetadata *metadata = [CDKConsoleDock sessionMetadata];
NSLog(@"%@", metadata.sessionIdentifier);
```

内置 UIKit 面板提供 `Mark`、`Timeline`、`Share Issue Report` 和 `Copy Issue Report`。同一份报告文本也可以通过 `ConsoleDock.issueReportText()` 或 `CDKConsoleDockUIKit.issueReportText` 读取，包含 session metadata、diagnostics、App Context、reproduction timeline、marker 索引和当前内存中保留的已脱敏日志。内置 Timeline 页和 issue report 的 reproduction timeline 都会按时间组合 marker、本地 Debug Action 执行记录，以及当前保留的 error/fault 日志。

App 可以提供本地上下文快照，用于内置 `Context` 页和 issue report：

```swift
ConsoleDock.setAppContextProvider {
    [
        .init(title: "App", items: [
            .init(key: "Environment", value: "staging")
        ])
    ]
}
```

App Context 按需读取，会经过一层基础的明显敏感字段脱敏，不会被 ConsoleDock 默认持久化、上传或自动发送。不要把原始密钥或不必要的个人信息放进 context value。

marker 本质上是带 `[marker]` 前缀的 native info 日志，因此同样经过脱敏、截断、详情、搜索、复制和分享流程。`Share Issue Report` 只会在用户主动分享时创建临时本地 `.txt` 文件交给系统 share sheet；`Copy Issue Report` 会把同一份报告文本复制到剪贴板。ConsoleDock 默认不会持久化、上传或自动发送 issue report。

## Local Session Archive

Local Session Archive 从 `v0.11.0` 开始属于已发布能力。它不会默认把所有日志写入磁盘，而是让测试人员或 App 显式保存当前 issue report 文本，方便 App 重启后继续查看这份复现证据。

```swift
let archive = try ConsoleDock.saveSessionArchive(note: "Checkout smoke test")
let archives = try ConsoleDock.sessionArchives()
try ConsoleDock.deleteSessionArchive(id: archive.id)
try ConsoleDock.clearSessionArchives()
```

内置 Logs 分享菜单提供 `Save Session Archive` 和 `Saved Session Archives`。保存的 archive 是有数量和长度上限的本地 issue-report 快照，内容来自已经脱敏/截断后的报告文本；它不是 raw log 数据库，不会上传，不会后台自动创建，也不保证捕获崩溃前最后一刻日志。

## Support Report

Support Report 从 `v0.14.0` 开始属于已发布能力。它适合接入到 App 自己的用户反馈、客服或测试反馈入口中，用来按需生成一个本地、已脱敏、带时间范围的报告。

```swift
let report = ConsoleDock.supportReport(options: .last10Minutes)
let fileURL = try ConsoleDock.makeTemporarySupportReportFile(options: .last60Minutes)
```

```objc
NSError *error = nil;
CDKSupportReport *report =
    [CDKConsoleDockUIKit supportReportWithLastMinutes:10
                          maximumReportCharacterCount:0];
NSURL *fileURL =
    [CDKConsoleDockUIKit makeTemporarySupportReportFileWithLastMinutes:60
                                           maximumReportCharacterCount:0
                                                                 error:&error];
```

默认时间范围是最近 10 分钟，也提供 5/10/30/60 分钟 preset 和指定日期范围。60 分钟适合较长的手动测试流程，但它仍然只会包含当前内存/session 中还保留的数据，并受到报告长度上限约束。ConsoleDock 不会做埋点、不会自动上传、不会后台持续写日志文件；临时 Support Report 文件只在调用时创建，并会清理 ConsoleDock 自己目录里的旧临时报告，避免无限累加。

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

该脚本会先确认工作区干净，再验证 SwiftPM manifest、package identity、Swift Package Index 元数据、Objective-C API surface、Swift API surface、UI accessibility identifiers、sample app 文档和自动化、Swift 格式、构建、测试、Release safety gates、文档链接、文档图片资产、开源治理元数据、分发文档和产物、公开发布内容审计、DocC、iOS package build、Swift/Objective-C 示例 App 构建、source archive 生成、source archive 内容和 source archive 独立构建/测试。GitHub workflow 会设置 `CONSOLEDOCK_RUN_UI_SMOKE=1`，因此 CI 会运行 Swift 和 Objective-C 示例 App 的 iOS Simulator UI smoke test；本地需要完整模拟器 smoke 路径时也可以设置同一个环境变量。

如果内置 UIKit 面板发生明显变化，发布前还应运行：

```sh
scripts/capture-swift-sample-screenshots.sh
```

这会从 Swift 示例 App 的 iOS Simulator UI automation 模式生成当前公开文档截图。

## 分发策略

当前唯一支持的公开分发渠道：

1. Swift Package Manager。

CocoaPods 和 XCFramework 不是当前主动发布目标。只有当真实旧项目或二进制分发需求证明 SPM 不够用时，才会重新评估。

更详细的分发策略见 [Distribution strategy](docs/distribution-strategy.md)。

仓库包含 Swift Package Index 元数据。PackageList 条目已通过 [SwiftPackageIndex/PackageList#14098](https://github.com/SwiftPackageIndex/PackageList/pull/14098) 合并；Swift Package Index 完成索引后，托管 package 和 DocC 页面才会稳定可访问。

ConsoleDock 当前不包含 CocoaPods、XCFramework、网络面板、崩溃采集、默认持久化、远程上传或第三方 logger 适配器。
