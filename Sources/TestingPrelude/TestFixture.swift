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
		let fileURL = bundle.url(forResource: jsonName, withExtension: ".json")

		let data = try orFail(file: file, line: line) { try Data(contentsOf: unwrap(fileURL, file: file, line: line)) }

		let decoder = JSONDecoder()
		let test = try orFail(file: file, line: line) { try decoder.decode(T.self, from: data) }

		try orFail(file: file, line: line) { try testFunction(test) }
	}
}
