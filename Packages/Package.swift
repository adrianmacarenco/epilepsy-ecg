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
            name: "AddDevice",
            targets: ["AddDevice"]
        ),
        .library(
            name: "AppFeature",
            targets: ["AppFeature"]
        ),
        .library(
            name: "BluetoothClient",
            targets: ["BluetoothClient"]),
        .library(
            name: "BluetoothManager",
            targets: ["BluetoothManager"]),
        .library(
            name: "Dashboard",
            targets: ["Dashboard"]
        ),
        .library(
            name: "DBClient",
            targets: ["DBClient"]
        ),
        .library(
            name: "DBManager",
            targets: ["DBManager"]
        ),
        .library(
            name: "ECG",
            targets: ["ECG"]
        ),
        .library(
            name: "ECG Settings",
            targets: ["ECG Settings"]
        ),

        .library(
            name: "Localizations",
            targets: ["Localizations"]
        ),
        .library(
            name: "Model",
            targets: ["Model"]
        ),
        .library(
            name: "HomeTabbar",
            targets: ["HomeTabbar"]
        ),
        .library(
            name: "Onboarding",
            targets: ["Onboarding"]
        ),
        .library(
            name: "Packages",
            targets: ["Packages"]
        ),
        .library(
            name: "PersistenceClient",
            targets: ["PersistenceClient"]
        ),
        .library(
            name: "Profile",
            targets: ["Profile"]
        ),
        .library(
            name: "StylePackage",
            targets: ["StylePackage"]
        ),
        .library(
            name: "Shared",
            targets: ["Shared"]
        ),
        .library(
            name: "TrackIntake",
            targets: ["TrackIntake"]
        ),
        .library(
            name: "UserCreation",
            targets: ["UserCreation"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "0.1.4"),
        .package(url: "https://github.com/pointfreeco/swift-identified-collections", from: "0.5.0"),
        .package(url: "https://github.com/pointfreeco/swift-clocks", from: "0.3.0"),
        .package(url: "https://github.com/pointfreeco/swiftui-navigation", from: "0.4.5"),
        .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", from: "0.3.1"),
        .package(url: "https://github.com/AppPear/ChartView", from: "1.5.3"),
        .package(url: "https://github.com/mikkojeronen/MovesenseApi-iOS.git", branch: "main"),
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.14.1")
    ],
    targets: [
        .target(
            name: "AddDevice",
            dependencies: [
                "StylePackage",
                "BluetoothClient",
                "PersistenceClient",
                .product(name: "IdentifiedCollections", package: "swift-identified-collections"),
                .product(name: "MovesenseApi", package: "MovesenseApi-iOS"),
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
        .target(
            name: "AppFeature",
            dependencies: [
                "DBClient",
                "BluetoothClient",
                "HomeTabbar",
                "StylePackage",
                "PersistenceClient",
                "UserCreation",
                .product(name: "IdentifiedCollections", package: "swift-identified-collections"),
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "SwiftUINavigation", package: "swiftui-navigation")
            ]
        ),
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
                .product(name: "MovesenseApi", package: "MovesenseApi-iOS"),
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "Clocks", package: "swift-clocks"),
            ]
        ),
        .target(
            name: "Dashboard",
            dependencies: [
            "AddDevice",
            "BluetoothClient",
            "DBClient",
            "ECG",
            "ECG Settings",
            "Model",
            "Onboarding",
            "Shared",
            "StylePackage",
            "PersistenceClient",
            .product(name: "Clocks", package: "swift-clocks"),
            .product(name: "Dependencies", package: "swift-dependencies"),
            .product(name: "IdentifiedCollections", package: "swift-identified-collections"),
            .product(name: "SwiftUINavigation", package: "swiftui-navigation"),
            .product(name: "SwiftUICharts", package: "ChartView"),
            .product(name: "MovesenseApi", package: "MovesenseApi-iOS")

            ]
        ),
        .target(
            name: "DBClient",
            dependencies: [
                "DBManager",
                "Model",
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "SQLite", package: "SQLite.swift")
            ]
        ),
        .target(
            name: "DBManager",
            dependencies: [
                "Model",
                .product(name: "SQLite", package: "SQLite.swift")
            ]
        ),
        .target(
            name: "ECG",
            dependencies: [
                "Model",
                "StylePackage",
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
        .target(
            name: "ECG Settings",
            dependencies: [
                "BluetoothClient",
                "ECG",
                "Model",
                "PersistenceClient",
                "StylePackage",
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "SwiftUINavigation", package: "swiftui-navigation"),
            ]
        ),
        .target(
            name: "Localizations",
            dependencies: []
        ),
        .target(
            name: "Model",
            dependencies: [
                .product(name: "MovesenseApi", package: "MovesenseApi-iOS")
            ]
        ),
        .target(
            name: "HomeTabbar",
            dependencies: [
                "Dashboard",
                "Profile",
                "StylePackage",
                "TrackIntake"
            ]
        ),
        .target(
            name: "Onboarding",
            dependencies: [
                "StylePackage"
            ]
        ),
        .target(
            name: "Packages",
            dependencies: []
        ),
        .target(
            name: "PersistenceClient",
            dependencies: [
                "Model",
                .product(name: "XCTestDynamicOverlay", package: "xctest-dynamic-overlay"),
                .product(name: "Dependencies", package: "swift-dependencies"),

            ]
        ),
        .target(
            name: "Profile",
            dependencies: [
                "StylePackage"
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
        .target(
            name: "Shared",
            dependencies: [
                "StylePackage"
            ]
        ),
        .target(
            name: "TrackIntake",
            dependencies: [
                "DBClient",
                "Model",
                "Shared",
                "StylePackage",
                "PersistenceClient",
                "UserCreation",
                .product(name: "SwiftUINavigation", package: "swiftui-navigation"),
                .product(name: "Dependencies", package: "swift-dependencies")
            ]
        ),
        .target(
            name: "UserCreation",
            dependencies: [
                "DBClient",
                "StylePackage",
                "Model",
                "Shared",
                "PersistenceClient",
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "SwiftUINavigation", package: "swiftui-navigation"),
            ]
        ),
        .testTarget(
            name: "PackagesTests",
            dependencies: ["Packages"]
        )
    ]
)
