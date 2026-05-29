// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
// Generated file. Do not edit.
//

import PackageDescription

let package = Package(
    name: "FlutterGeneratedPluginSwiftPackage",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "FlutterGeneratedPluginSwiftPackage", type: .static, targets: ["FlutterGeneratedPluginSwiftPackage"])
    ],
    dependencies: [
        .package(name: "shared_preferences_foundation", path: "../.packages/shared_preferences_foundation-2.5.6"),
        .package(name: "firebase_storage", path: "../.packages/firebase_storage-12.4.10"),
        .package(name: "firebase_core", path: "../.packages/firebase_core-3.15.2"),
        .package(name: "firebase_auth", path: "../.packages/firebase_auth-5.7.0"),
        .package(name: "cloud_firestore", path: "../.packages/cloud_firestore-5.6.12"),
        .package(name: "FlutterFramework", path: "../.packages/FlutterFramework")
    ],
    targets: [
        .target(
            name: "FlutterGeneratedPluginSwiftPackage",
            dependencies: [
                .product(name: "shared-preferences-foundation", package: "shared_preferences_foundation"),
                .product(name: "firebase-storage", package: "firebase_storage"),
                .product(name: "firebase-core", package: "firebase_core"),
                .product(name: "firebase-auth", package: "firebase_auth"),
                .product(name: "cloud-firestore", package: "cloud_firestore"),
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
