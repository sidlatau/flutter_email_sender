// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "flutter_email_sender_method_channel",
    platforms: [
        .macOS("10.15"),
    ],
    products: [
        .library(name: "flutter-email-sender-method-channel", targets: ["flutter_email_sender_method_channel"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "flutter_email_sender_method_channel",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            path: "Sources/flutter_email_sender",
            resources: [
                .process("PrivacyInfo.xcprivacy"),
            ]
        )
    ]
)
