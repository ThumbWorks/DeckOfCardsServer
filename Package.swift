// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "DeckOfCardsServer",
    products: [
        .library(name: "DeckOfCardsServer", targets: ["App"]),
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),

        // 🕸 For making the websites
        .package(url: "https://github.com/vapor/leaf.git", from: "3.0.0"),

        // 🔵 Swift ORM (queries, models, relations, etc) built on SQLite 3.
        .package(url: "https://github.com/vapor/fluent-sqlite.git", from: "3.0.0"),

        // 🔒 Some basic auth requirements
        .package(url: "https://github.com/vapor/auth.git", from: "2.0.0"),

    ],
    targets: [
        .target(name: "App", dependencies: ["FluentSQLite", "Vapor", "Leaf", "Authentication"]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"])
    ]
)

