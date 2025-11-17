// swift-tools-version:5.7

import PackageDescription

let package = Package(
    name: "IQPaywallViewController",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "IQPaywallViewController",
            targets: ["IQPaywallViewController"]
        )
    ],
    targets: [
        .target(name: "IQPaywallViewController",
            path: "IQPaywallViewController",
            resources: [
                .copy("Assets/PrivacyInfo.xcprivacy")
            ],
            linkerSettings: [
                .linkedFramework("UIKit")
            ]
        )
    ]
)
