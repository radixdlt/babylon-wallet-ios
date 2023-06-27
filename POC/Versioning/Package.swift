// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "Versioning",
	targets: [
		.target(
			name: "SingleVersion"),
		.testTarget(
			name: "SingleVersionTests",
			dependencies: ["SingleVersion"]
		),
	]
)
