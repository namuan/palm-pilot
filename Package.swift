// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "PalmPilot",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(name: "PalmPilot", targets: ["PalmPilot"]),
    ],
    targets: [
        .executableTarget(
            name: "PalmPilot",
            path: "Sources",
            linkerSettings: [
                .linkedFramework("AVFoundation"),
                .linkedFramework("Vision"),
                .linkedFramework("AppKit"),
                .linkedFramework("CoreGraphics"),
                .linkedFramework("CoreMedia"),
                .linkedFramework("CoreVideo"),
            ]
        ),
    ]
)
