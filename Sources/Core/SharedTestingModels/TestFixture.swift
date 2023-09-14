import Prelude
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftCrypto open source project
//
// Copyright (c) 2019-2020 Apple Inc. and the SwiftCrypto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.md for the list of SwiftCrypto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
import XCTest

extension XCTestCase {
	public func readTestFixtureData(
		bundle: Bundle,
		jsonName: String,
		file: StaticString = #filePath,
		line: UInt = #line
	) throws -> Data {
		let fileURL = try XCTUnwrap(
			bundle.url(forResource: jsonName, withExtension: ".json"),
			file: file,
			line: line
		)

		return try Data(contentsOf: fileURL)
	}

	public func readTestFixture<T: Decodable>(
		bundle: Bundle,
		jsonName: String,
		jsonDecoder: JSONDecoder = .iso8601,
		file: StaticString = #filePath,
		line: UInt = #line
	) throws -> T {
		let data = try readTestFixtureData(
			bundle: bundle,
			jsonName: jsonName,
			file: file,
			line: line
		)

		return try jsonDecoder.decode(T.self, from: data)
	}

	public func testFixture<T: Decodable>(
		bundle: Bundle,
		jsonName: String,
		jsonDecoder: JSONDecoder = .iso8601,
		file: StaticString = #filePath,
		line: UInt = #line,
		testFunction: (T) throws -> Void
	) throws {
		let test: T = try readTestFixture(
			bundle: bundle,
			jsonName: jsonName,
			jsonDecoder: jsonDecoder,
			file: file, line: line
		)

		try testFunction(test)
	}
}
