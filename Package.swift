// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "FourteenDayNote",
    defaultLocalization: "ja",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "FourteenDayCore",
            targets: ["FourteenDayCore"]
        ),
        .executable(
            name: "content-lint",
            targets: ["ContentLint"]
        ),
    ],
    targets: [
        .target(
            name: "FourteenDayCore",
            resources: [
                .copy("Resources/Content"),
            ]
        ),
        .executableTarget(
            name: "ContentLint",
            dependencies: ["FourteenDayCore"]
        ),
        .testTarget(
            name: "FourteenDayCoreTests",
            dependencies: ["FourteenDayCore"]
        ),
    ]
)

