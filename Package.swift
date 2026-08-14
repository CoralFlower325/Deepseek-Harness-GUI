// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "DeepSeekHarnessMac",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(name: "DeepSeekHarnessMac", targets: ["DeepSeekHarnessMac"]),
    ],
    targets: [
        .executableTarget(
            name: "DeepSeekHarnessMac",
            path: "Sources/DeepSeekHarnessMac",
            swiftSettings: [
                .swiftLanguageMode(.v5),
            ]
        ),
    ]
)
