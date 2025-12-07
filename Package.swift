// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacOSWorkspaceMCPServer",
    platforms: [
        .macOS(.v15)
    ],
    dependencies: [
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk", from: "0.10.0")
    ],
    targets: [
        .executableTarget(
            name: "MacOSWorkspaceMCPServer",
            dependencies: [
                .product(name: "MCP", package: "swift-sdk")
            ]
        ),
        .testTarget(
            name: "MacOSWorkspaceMCPServerTests",
            dependencies: ["MacOSWorkspaceMCPServer"]
        ),
    ]
)
