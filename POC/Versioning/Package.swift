// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "Versioning",
	platforms: [.macOS(.v13), .iOS(.v16)],
	dependencies: [
		.package(url: "https://github.com/davdroman/swift-json-testing", from: "0.1.0"),
		.package(url: "https://github.com/jrothwell/VersionedCodable", from: "1.0.1"),
	],
	targets: [
		.target(
			name: "TestUtils",
			dependencies: [
				.product(name: "JSONTesting", package: "swift-json-testing"),
			]
		),
		.target(
			name: "SingleTypeGlobalSharedVersionNumber"
		),
		.testTarget(
			name: "SingleTypeGlobalSharedVersionNumberTests",
			dependencies: [
				"SingleTypeGlobalSharedVersionNumber",
				"TestUtils",
			]
		),
		.target(
			name: "SingleTypeUniqueVersionNumberPerType"
		),
		.testTarget(
			name: "SingleTypeUniqueVersionNumberPerTypeTests",
			dependencies: [
				"SingleTypeUniqueVersionNumberPerType",
				"TestUtils",
			]
		),

		.target(
			name: "MultipleTypesForEachModelVersionedCodable",
			dependencies: [
				"VersionedCodable",
			]
		),
		.testTarget(
			name: "MultipleTypesForEachModelVersionedCodableTests",
			dependencies: [
				"MultipleTypesForEachModelVersionedCodable",
				"TestUtils",
			]
		),
	]
)
