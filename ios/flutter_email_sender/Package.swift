// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "flutter_email_sender",
    platforms: [
        .iOS("12.0"),
    ],
    products: [
        .library(name: "flutter-email-sender", targets: ["flutter_email_sender"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "flutter_email_sender",
            dependencies: [],
            resources: [
                .process("PrivacyInfo.xcprivacy"),
            ]
        )
    ]
)
