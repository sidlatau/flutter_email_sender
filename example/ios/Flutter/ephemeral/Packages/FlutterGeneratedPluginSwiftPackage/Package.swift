// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
//  Generated file. Do not edit.
//

import PackageDescription

let package = Package(
    name: "FlutterGeneratedPluginSwiftPackage",
    platforms: [
        .iOS("12.0")
    ],
    products: [
        .library(name: "FlutterGeneratedPluginSwiftPackage", type: .static, targets: ["FlutterGeneratedPluginSwiftPackage"])
    ],
    dependencies: [
        .package(name: "image_picker_ios", path: "/Users/ts/.pub-cache/hosted/pub.dev/image_picker_ios-0.8.12+1/ios/image_picker_ios"),
        .package(name: "path_provider_foundation", path: "/Users/ts/.pub-cache/hosted/pub.dev/path_provider_foundation-2.4.1/darwin/path_provider_foundation"),
        .package(name: "flutter_email_sender", path: "/Users/ts/Documents/github/personal/flutter_email_sender/ios/flutter_email_sender")
    ],
    targets: [
        .target(
            name: "FlutterGeneratedPluginSwiftPackage",
            dependencies: [
                .product(name: "image-picker-ios", package: "image_picker_ios"),
                .product(name: "path-provider-foundation", package: "path_provider_foundation"),
                .product(name: "flutter-email-sender", package: "flutter_email_sender")
            ]
        )
    ]
)
