// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "Tooltip",
    products: [
        .library(
            name: "Tooltip",
            targets: ["Tooltip"]),
    ],
    targets: [
        .target(
            name: "Tooltip",
            dependencies: [],
            path: "Sources"),
    ]
)
