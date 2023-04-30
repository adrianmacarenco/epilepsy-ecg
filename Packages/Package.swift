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
            name: "Packages",
            targets: ["Packages"]
        ),
        .library(
            name: "Model",
            targets: ["Model"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "0.1.4"),
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
            dependencies: []),
        .testTarget(
            name: "PackagesTests",
            dependencies: ["Packages"]),
    ]
)
