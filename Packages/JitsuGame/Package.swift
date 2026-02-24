// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "JitsuGame",
    platforms: [.iOS(.v26)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "JitsuGame",
            targets: ["JitsuGame"]
        ),
    ],
    dependencies: [.package(path: "../JitsuCore"), .package(path: "../JitsuMatch")],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "JitsuGame",
            dependencies: ["JitsuCore", "JitsuMatch"]
        ),
        .testTarget(
            name: "JitsuGameTests",
            dependencies: ["JitsuGame"]
        ),
    ]
)
