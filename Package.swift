// swift-tools-version:5.6

import PackageDescription

let package = Package(
    name: "KakaoHealthcareCalendar",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "KakaoHealthcareCalendar",
            targets: ["KakaoHealthcareCalendar"]
        )
    ],
    targets: [
        .target(
            name: "KakaoHealthcareCalendar",
            path: "Sources"
        )
    ]
)
