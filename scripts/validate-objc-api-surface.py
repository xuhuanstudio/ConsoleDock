#!/usr/bin/env python3
"""Validate the Objective-C-compatible public API surface."""

from __future__ import annotations

import argparse
import json
import pathlib
import re
import subprocess
import sys
import tempfile


CORE_HEADER = pathlib.Path("Sources/ConsoleDockCore/include/ConsoleDockCore.h")
CORE_TARGET = "ConsoleDockCore"
EXPECTED_PUBLIC_HEADERS_PATH = "include"

REQUIRED_SNIPPETS = [
    "typedef NS_ENUM(NSInteger, CDKLogLevel)",
    "CDKLogLevelDebug",
    "CDKLogLevelInfo",
    "CDKLogLevelWarning",
    "CDKLogLevelError",
    "CDKLogLevelFault",
    "typedef NS_ENUM(NSInteger, CDKLogSource)",
    "CDKLogSourceNative",
    "CDKLogSourceStdout",
    "CDKLogSourceStderr",
    "typedef NS_ENUM(NSInteger, CDKStartResult)",
    "CDKStartResultStarted",
    "CDKStartResultAlreadyRunning",
    "CDKStartResultDisabled",
    "CDKStartResultFailed",
    "typedef NS_ENUM(NSInteger, CDKFloatingButtonPosition)",
    "CDKFloatingButtonPositionTopLeading",
    "CDKFloatingButtonPositionTopTrailing",
    "CDKFloatingButtonPositionBottomLeading",
    "CDKFloatingButtonPositionBottomTrailing",
    "FOUNDATION_EXPORT NSErrorDomain const CDKConsoleDockErrorDomain;",
    "FOUNDATION_EXPORT NSNotificationName const CDKConsoleDockEntriesDidChangeNotification;",
    "FOUNDATION_EXPORT NSNotificationName const CDKConsoleDockDiagnosticsDidChangeNotification;",
    "typedef NSString * _Nonnull (^CDKRedactionBlock)(NSString *message);",
    "@interface CDKConfiguration : NSObject <NSCopying>",
    "@property (nonatomic) NSUInteger maximumEntries;",
    "@property (nonatomic) NSUInteger maximumMessageLength;",
    "@property (nonatomic) BOOL captureStandardOutput;",
    "@property (nonatomic) BOOL captureStandardError;",
    "@property (nonatomic) BOOL showsFloatingButton;",
    "@property (nonatomic) CDKFloatingButtonPosition floatingButtonPosition;",
    "@property (nonatomic) BOOL allowsReleaseBuilds;",
    "@property (nonatomic, copy, nullable) CDKRedactionBlock redactionBlock;",
    "+ (instancetype)defaultConfiguration;",
    "@interface CDKLogEntry : NSObject <NSCopying>",
    "@property (nonatomic, readonly) unsigned long long identifier;",
    "@property (nonatomic, copy, readonly) NSDate *timestamp;",
    "@property (nonatomic, readonly) CDKLogLevel level;",
    "@property (nonatomic, readonly) CDKLogSource source;",
    "@property (nonatomic, copy, readonly) NSString *message;",
    "@property (nonatomic, readonly, getter=isMarker) BOOL marker;",
    "@property (nonatomic, readonly, getter=isPartial) BOOL partial;",
    "@property (nonatomic, readonly) BOOL redacted;",
    "@property (nonatomic, readonly) BOOL truncated;",
    "- (instancetype)initWithIdentifier:(unsigned long long)identifier timestamp:(NSDate *)timestamp level:(CDKLogLevel)level source:(CDKLogSource)source message:(NSString *)message;",
    "- (instancetype)initWithIdentifier:(unsigned long long)identifier timestamp:(NSDate *)timestamp level:(CDKLogLevel)level source:(CDKLogSource)source message:(NSString *)message redacted:(BOOL)redacted truncated:(BOOL)truncated;",
    "- (instancetype)initWithIdentifier:(unsigned long long)identifier timestamp:(NSDate *)timestamp level:(CDKLogLevel)level source:(CDKLogSource)source message:(NSString *)message isPartial:(BOOL)isPartial redacted:(BOOL)redacted truncated:(BOOL)truncated;",
    "- (instancetype)initWithIdentifier:(unsigned long long)identifier timestamp:(NSDate *)timestamp level:(CDKLogLevel)level source:(CDKLogSource)source message:(NSString *)message isPartial:(BOOL)isPartial isMarker:(BOOL)isMarker redacted:(BOOL)redacted truncated:(BOOL)truncated NS_DESIGNATED_INITIALIZER;",
    "- (instancetype)initWithTimestamp:(NSDate *)timestamp level:(CDKLogLevel)level source:(CDKLogSource)source message:(NSString *)message;",
    "@interface CDKDiagnostics : NSObject <NSCopying>",
    "@property (nonatomic, readonly, getter=isRunning) BOOL running;",
    "@property (nonatomic, readonly) BOOL captureStandardOutput;",
    "@property (nonatomic, readonly) BOOL captureStandardError;",
    "@property (nonatomic, readonly) BOOL showsFloatingButton;",
    "@property (nonatomic, readonly) CDKFloatingButtonPosition floatingButtonPosition;",
    "@property (nonatomic, readonly) BOOL allowsReleaseBuilds;",
    "@property (nonatomic, readonly) NSUInteger maximumEntries;",
    "@property (nonatomic, readonly) NSUInteger maximumMessageLength;",
    "@property (nonatomic, readonly) NSUInteger entryCount;",
    "@property (nonatomic, readonly) NSUInteger redactedEntryCount;",
    "@property (nonatomic, readonly) NSUInteger truncatedEntryCount;",
    "@property (nonatomic, readonly) NSUInteger partialEntryCount;",
    "- (instancetype)initWithRunning:(BOOL)running captureStandardOutput:(BOOL)captureStandardOutput captureStandardError:(BOOL)captureStandardError showsFloatingButton:(BOOL)showsFloatingButton floatingButtonPosition:(CDKFloatingButtonPosition)floatingButtonPosition allowsReleaseBuilds:(BOOL)allowsReleaseBuilds maximumEntries:(NSUInteger)maximumEntries maximumMessageLength:(NSUInteger)maximumMessageLength entryCount:(NSUInteger)entryCount redactedEntryCount:(NSUInteger)redactedEntryCount truncatedEntryCount:(NSUInteger)truncatedEntryCount partialEntryCount:(NSUInteger)partialEntryCount NS_DESIGNATED_INITIALIZER;",
    "@interface CDKSessionMetadata : NSObject <NSCopying>",
    "@property (nonatomic, copy, readonly) NSString *sessionIdentifier;",
    "@property (nonatomic, copy, readonly, nullable) NSDate *startedAt;",
    "@property (nonatomic, copy, readonly) NSDate *generatedAt;",
    "@property (nonatomic, copy, readonly, nullable) NSString *bundleIdentifier;",
    "@property (nonatomic, copy, readonly, nullable) NSString *appVersion;",
    "@property (nonatomic, copy, readonly, nullable) NSString *appBuild;",
    "@property (nonatomic, copy, readonly) NSString *processName;",
    "@property (nonatomic, copy, readonly) NSString *operatingSystemVersion;",
    "@property (nonatomic, copy, readonly) NSString *deviceModel;",
    "@property (nonatomic, copy, readonly) NSString *localeIdentifier;",
    "@property (nonatomic, copy, readonly) NSString *timeZoneIdentifier;",
    "- (instancetype)initWithSessionIdentifier:(NSString *)sessionIdentifier startedAt:(nullable NSDate *)startedAt generatedAt:(NSDate *)generatedAt bundleIdentifier:(nullable NSString *)bundleIdentifier appVersion:(nullable NSString *)appVersion appBuild:(nullable NSString *)appBuild processName:(NSString *)processName operatingSystemVersion:(NSString *)operatingSystemVersion deviceModel:(NSString *)deviceModel localeIdentifier:(NSString *)localeIdentifier timeZoneIdentifier:(NSString *)timeZoneIdentifier NS_DESIGNATED_INITIALIZER;",
    "@interface CDKLogForwarder : NSObject",
    "@property (nonatomic, copy, readonly, nullable) NSString *category;",
    "@property (nonatomic, readonly) CDKLogLevel minimumLevel;",
    "- (instancetype)init;",
    "- (instancetype)initWithCategory:(nullable NSString *)category minimumLevel:(CDKLogLevel)minimumLevel NS_DESIGNATED_INITIALIZER;",
    "- (void)logWithLevel:(CDKLogLevel)level message:(NSString *)message;",
    "- (void)debug:(NSString *)message;",
    "- (void)info:(NSString *)message;",
    "- (void)warning:(NSString *)message;",
    "- (void)error:(NSString *)message;",
    "- (void)fault:(NSString *)message;",
    "@interface CDKLineEvent : NSObject <NSCopying>",
    "@property (nonatomic, readonly) CDKLogSource source;",
    "@property (nonatomic, copy, readonly) NSString *message;",
    "@property (nonatomic, readonly, getter=isPartial) BOOL partial;",
    "- (instancetype)initWithSource:(CDKLogSource)source message:(NSString *)message isPartial:(BOOL)isPartial NS_DESIGNATED_INITIALIZER;",
    "@interface CDKLineFramer : NSObject",
    "@property (nonatomic, readonly) NSUInteger maximumPartialBytes;",
    "- (instancetype)initWithMaximumPartialBytes:(NSUInteger)maximumPartialBytes NS_DESIGNATED_INITIALIZER;",
    "- (NSArray<CDKLineEvent *> *)appendData:(NSData *)data source:(CDKLogSource)source;",
    "- (NSArray<CDKLineEvent *> *)flushSource:(CDKLogSource)source;",
    "@interface CDKConsoleDock : NSObject",
    "+ (CDKStartResult)startWithConfiguration:(nullable CDKConfiguration *)configuration;",
    "+ (CDKStartResult)startWithConfiguration:(nullable CDKConfiguration *)configuration error:(NSError * _Nullable * _Nullable)error;",
    "+ (void)stop;",
    "+ (BOOL)isRunning;",
    "+ (CDKDiagnostics *)diagnostics;",
    "+ (CDKSessionMetadata *)sessionMetadata;",
    "+ (NSArray<CDKLogEntry *> *)entries;",
    "+ (void)clearEntries;",
    "+ (void)appendLineEvent:(CDKLineEvent *)event;",
    "+ (void)logWithLevel:(CDKLogLevel)level message:(NSString *)message;",
    "+ (void)mark:(NSString *)message;",
    "+ (void)debug:(NSString *)message;",
    "+ (void)info:(NSString *)message;",
    "+ (void)warning:(NSString *)message;",
    "+ (void)error:(NSString *)message;",
    "+ (void)fault:(NSString *)message;",
]

DENIED_PUBLIC_SNIPPETS = [
    "CDKStandardOutputCapture",
    "CDKDescriptorCapture",
]

INTERFACE_RE = re.compile(r"@interface\s+([A-Za-z_][A-Za-z0-9_]*)")
ENUM_RE = re.compile(r"typedef\s+NS_ENUM\s*\([^)]*,\s*([A-Za-z_][A-Za-z0-9_]*)\)")
CONSTANT_RE = re.compile(r"FOUNDATION_EXPORT\s+[^;]*\s+const\s+([A-Za-z_][A-Za-z0-9_]*)\s*;")
TYPEDEF_RE = re.compile(r"typedef\s+[^;]*\(\^([A-Za-z_][A-Za-z0-9_]*)\)")


def normalized(text: str) -> str:
    return re.sub(r"\s+", " ", text).strip()


def package_target(root: pathlib.Path, target_name: str) -> dict[str, object] | None:
    output = subprocess.check_output(["swift", "package", "dump-package"], cwd=root)
    package = json.loads(output)
    for target in package.get("targets", []):
        if target.get("name") == target_name:
            return target
    return None


def validate_public_headers_path(root: pathlib.Path) -> list[str]:
    target = package_target(root, CORE_TARGET)
    if target is None:
        return [f"Package.swift must contain target {CORE_TARGET}"]

    public_headers_path = target.get("publicHeadersPath")
    if public_headers_path != EXPECTED_PUBLIC_HEADERS_PATH:
        return [
            f"{CORE_TARGET} publicHeadersPath must be "
            f"{EXPECTED_PUBLIC_HEADERS_PATH}, got {public_headers_path}"
        ]
    return []


def validate_header(root: pathlib.Path) -> list[str]:
    errors: list[str] = []
    header_path = root / CORE_HEADER
    if not header_path.exists():
        return [f"{CORE_HEADER}: missing public umbrella header"]

    text = header_path.read_text(encoding="utf-8")
    compact_text = normalized(text)

    if "#import <Foundation/Foundation.h>" not in text:
        errors.append(f"{CORE_HEADER}: must import Foundation")
    if "NS_ASSUME_NONNULL_BEGIN" not in text or "NS_ASSUME_NONNULL_END" not in text:
        errors.append(f"{CORE_HEADER}: must define a nullability region")

    for snippet in REQUIRED_SNIPPETS:
        if normalized(snippet) not in compact_text:
            errors.append(f"{CORE_HEADER}: missing required public API snippet: {snippet}")

    for snippet in DENIED_PUBLIC_SNIPPETS:
        if snippet in text:
            errors.append(f"{CORE_HEADER}: internal symbol must not be public: {snippet}")

    for interface_name in INTERFACE_RE.findall(text):
        if not interface_name.startswith("CDK"):
            errors.append(f"{CORE_HEADER}: public Objective-C interface lacks CDK prefix: {interface_name}")

    for enum_name in ENUM_RE.findall(text):
        if not enum_name.startswith("CDK"):
            errors.append(f"{CORE_HEADER}: public enum lacks CDK prefix: {enum_name}")

    for constant_name in CONSTANT_RE.findall(text):
        if not constant_name.startswith("CDK"):
            errors.append(f"{CORE_HEADER}: public constant lacks CDK prefix: {constant_name}")

    for typedef_name in TYPEDEF_RE.findall(text):
        if not typedef_name.startswith("CDK"):
            errors.append(f"{CORE_HEADER}: public typedef lacks CDK prefix: {typedef_name}")

    return errors


def validate(root: pathlib.Path) -> list[str]:
    errors: list[str] = []
    errors.extend(validate_public_headers_path(root))
    errors.extend(validate_header(root))
    return errors


def write_package_manifest(root: pathlib.Path, public_headers_path: str = EXPECTED_PUBLIC_HEADERS_PATH) -> None:
    root.mkdir(parents=True, exist_ok=True)
    (root / "Package.swift").write_text(
        f"""// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ConsoleDock",
    products: [
        .library(name: "ConsoleDockCore", targets: ["ConsoleDockCore"])
    ],
    targets: [
        .target(name: "ConsoleDockCore", publicHeadersPath: "{public_headers_path}")
    ]
)
""",
        encoding="utf-8",
    )


def write_valid_header(root: pathlib.Path, extra_text: str = "") -> None:
    header_path = root / CORE_HEADER
    header_path.parent.mkdir(parents=True, exist_ok=True)
    header_path.write_text(
        "#import <Foundation/Foundation.h>\n\n"
        "NS_ASSUME_NONNULL_BEGIN\n\n"
        + "\n".join(REQUIRED_SNIPPETS)
        + "\n"
        + extra_text
        + "\nNS_ASSUME_NONNULL_END\n",
        encoding="utf-8",
    )


def write_valid_fixture(root: pathlib.Path, public_headers_path: str = EXPECTED_PUBLIC_HEADERS_PATH) -> None:
    write_package_manifest(root, public_headers_path)
    write_valid_header(root)


def self_test() -> list[str]:
    errors: list[str] = []

    with tempfile.TemporaryDirectory(prefix="consoledock-objc-api-surface-self-test-") as raw_directory:
        root = pathlib.Path(raw_directory)
        write_valid_fixture(root)
        if validate(root):
            errors.append("validate should accept the expected Objective-C public API surface")

        missing_required_root = root / "missing-required"
        write_valid_fixture(missing_required_root)
        header = missing_required_root / CORE_HEADER
        header.write_text(
            header.read_text(encoding="utf-8").replace(
                "+ (void)fault:(NSString *)message;\n",
                "",
            ),
            encoding="utf-8",
        )
        if not validate(missing_required_root):
            errors.append("validate should reject missing required Objective-C core APIs")

        unprefixed_root = root / "unprefixed"
        write_valid_fixture(unprefixed_root)
        write_valid_header(
            unprefixed_root,
            extra_text="@interface ConsoleDockLeak : NSObject\n@end\n",
        )
        if not validate(unprefixed_root):
            errors.append("validate should reject public Objective-C interfaces without the CDK prefix")

        denied_internal_root = root / "denied-internal"
        write_valid_fixture(denied_internal_root)
        write_valid_header(
            denied_internal_root,
            extra_text="@interface CDKStandardOutputCapture : NSObject\n@end\n",
        )
        if not validate(denied_internal_root):
            errors.append("validate should reject internal capture symbols in the public Objective-C header")

        wrong_headers_path_root = root / "wrong-headers-path"
        write_valid_fixture(wrong_headers_path_root, public_headers_path="Public")
        if not validate(wrong_headers_path_root):
            errors.append("validate should reject a ConsoleDockCore target without publicHeadersPath include")

    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "root",
        nargs="?",
        default=pathlib.Path(__file__).resolve().parents[1],
        type=pathlib.Path,
        help="Repository root. Defaults to the parent of the scripts directory.",
    )
    parser.add_argument("--self-test", action="store_true", help="Run local validator self-tests.")
    args = parser.parse_args()

    if args.self_test:
        errors = self_test()
        if errors:
            print("Objective-C API surface validator self-test failed:", file=sys.stderr)
            for error in errors:
                print(f"- {error}", file=sys.stderr)
            return 1

        print("Objective-C API surface validator self-test passed.")
        return 0

    root = args.root.resolve()
    errors = validate(root)
    if errors:
        print("Objective-C API surface validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print("Objective-C API surface validation passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
