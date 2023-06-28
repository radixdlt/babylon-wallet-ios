// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "Versioning",
	platforms: [.macOS(.v13), .iOS(.v16)],
	dependencies: [
		.package(url: "https://github.com/davdroman/swift-json-testing", from: "0.1.0"),
	],
	targets: [
		.target(
			name: "SingleVersion"
		),
		.testTarget(
			name: "SingleVersionTests",
			dependencies: [
				"SingleVersion",
				.product(name: "JSONTesting", package: "swift-json-testing"),
			]
		),
	]
)
