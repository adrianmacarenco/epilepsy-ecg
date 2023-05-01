// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Packages",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "BluetoothClient",
            targets: ["BluetoothClient"]),
        .library(
            name: "BluetoothManager",
            targets: ["BluetoothManager"]),
        .library(
            name: "Model",
            targets: ["Model"]
        ),
        .library(
            name: "Packages",
            targets: ["Packages"]
        ),
        .library(
            name: "ScanDevices",
            targets: ["ScanDevices"]
        ),
        .library(
            name: "StylePackage",
            targets: ["StylePackage"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "0.1.4"),
        .package(url: "https://github.com/pointfreeco/swift-identified-collections", from: "0.5.0"),
        .package(url: "https://github.com/mikkojeronen/MovesenseApi-iOS.git", branch: "main")
    ],
    targets: [
        .target(
            name: "BluetoothClient",
            dependencies: [
                "Model",
                "BluetoothManager",
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "MovesenseApi", package: "MovesenseApi-iOS")
            ]
        ),
        .target(
            name: "BluetoothManager",
            dependencies: [
                "Model",
                .product(name: "MovesenseApi", package: "MovesenseApi-iOS")
            ]
        ),
        .target(
            name: "Model",
            dependencies: []
        ),
        .target(
            name: "Packages",
            dependencies: []
        ),
        .target(
            name: "ScanDevices",
            dependencies: [
                "StylePackage",
                "BluetoothClient",
                .product(name: "IdentifiedCollections", package: "swift-identified-collections"),
                .product(name: "MovesenseApi", package: "MovesenseApi-iOS"),
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
        .target(
            name: "StylePackage",
            dependencies: [],
            resources: [
                .process("Fonts"),
//                .copy("Images.xcassets"),
                .copy("Colors.xcassets")
            ]
        ),
        .testTarget(
            name: "PackagesTests",
            dependencies: ["Packages"]
        )
    ]
)
