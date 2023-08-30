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
  dependencies: [
    .package(
      url: "https://github.com/WenchaoD/FSCalendar.git",
      .upToNextMajor(from: "2.8.3")
    )
  ],
  targets: [
    .target(
      name: "KakaoHealthcareCalendar",
      dependencies: [
        .product(name: "FSCalendar", package: "FSCalendar")
      ],
      path: "Sources"
      
    )
  ]
)
