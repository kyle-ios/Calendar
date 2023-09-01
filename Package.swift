// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

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
//
//
//let package = Package(
//    name: "HealthcareCalendar",
//    products: [
//        .library(
//            name: "HealthcareCalendar",
//            targets: ["HealthcareCalendar"]),
//    ],
//    dependencies: [
//        
//    ],
//    targets: [
//        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
//        // Targets can depend on other targets in this package, and on products in packages this package depends on.
//        .target(
//            name: "HealthcareCalendar",
//            dependencies: []),
//        .testTarget(
//            name: "HealthcareCalendarTests",
//            dependencies: ["HealthcareCalendar"]),
//    ]
//)
