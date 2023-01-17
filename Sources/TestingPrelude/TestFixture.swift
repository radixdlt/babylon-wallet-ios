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

public extension XCTestCase {
	func testFixture<T: Decodable>(
		bundle: Bundle,
		jsonName: String,
		file: StaticString = #file,
		line: UInt = #line,
		testFunction: (T) throws -> Void
	) throws {
		let fileURL = try XCTUnwrap(
			bundle.url(forResource: jsonName, withExtension: ".json"),
			file: file,
			line: line
		)

		let data = try Data(contentsOf: fileURL)

		let decoder = JSONDecoder()
		let test = try decoder.decode(T.self, from: data)

		try testFunction(test)
	}
}
