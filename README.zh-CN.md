# ConsoleDock

面向 iOS 测试场景的 App 内调试日志面板。

ConsoleDock 是一个早期阶段的 iOS debug SDK，目标是让测试人员在真机或模拟器上直接查看 App 日志，减少为了看基础日志而实时连接 Xcode 的依赖。

> 说明：英文 [README](README.md)、DocC 和 `docs/` 是项目的权威文档。本文是中文概览，方便快速理解项目定位和接入方式。

## 当前状态

ConsoleDock 目前处于 `v0.1.0` 公开预览前的 MVP hardening 阶段。仓库已经包含：

- Swift Package Manager package；
- Objective-C/C 兼容的 `ConsoleDockCore`；
- Swift facade `ConsoleDock`；
- stdout/stderr 文件描述符捕获、透传和恢复；
- 本地内存日志存储；
- 默认敏感字段脱敏；
- UIKit 浮动按钮和日志面板；
- Swift 和 Objective-C 示例 App；
- Release 默认禁用保护；
- DocC、CI、release validation 和开源治理文档。

## 能力边界

ConsoleDock 不是 Xcode Console、LLDB、系统日志或 Apple unified logging 的完整替代品。

ConsoleDock 可以覆盖：

- Swift `print`；
- C `printf` / `fprintf`；
- stdout / stderr；
- 很多通过进程 stderr 输出的 `NSLog`；
- 通过 ConsoleDock 显式 API 写入的日志。

ConsoleDock 不承诺完整、稳定、零侵入捕获：

- Swift `Logger`；
- `os_log`；
- Apple unified logging；
- 其他 App 或系统进程日志；
- 断点、LLDB 表达式、sanitizer 诊断等调试器能力。

如果需要可靠完整的 App 内日志展示，推荐使用 ConsoleDock 的显式 API，或者在已有 logger 中增加 sink/appender 转发。

## Swift 快速开始

```swift
import ConsoleDock

ConsoleDock.start()

ConsoleDock.info("Login succeeded")
print("Visible through stdout capture")
```

Debug 构建下，默认配置会启用 stdout/stderr 捕获，安装浮动 `CD` 按钮，进行基础敏感字段脱敏，并把日志保存在本地内存中。

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

该脚本会先确认工作区干净，再验证 SwiftPM manifest、Swift Package Index 元数据、Objective-C API surface、Swift 格式、构建、测试、Release safety gates、文档链接、公开发布内容审计、DocC、iOS package build、Swift/Objective-C 示例 App 构建、source archive 生成和 source archive 内容。

## 分发计划

当前优先级：

1. Swift Package Manager；
2. CocoaPods，等 SPM package 稳定后再考虑；
3. XCFramework，等公开 API 稳定后再考虑。

仓库包含 Swift Package Index 元数据，公开并打 tag 后可用于托管 DocC 文档。

ConsoleDock 当前不包含 CocoaPods、XCFramework、网络面板、崩溃采集、默认持久化、远程上传或第三方 logger 适配器。
