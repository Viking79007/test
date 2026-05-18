// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "TelegramKeywordNotifier",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "TelegramKeywordNotifier",
            targets: ["TelegramKeywordNotifier"]
        )
    ],
    targets: [
        .executableTarget(
            name: "TelegramKeywordNotifier"
        )
    ]
)
