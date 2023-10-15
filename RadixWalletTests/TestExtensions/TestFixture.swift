@testable import Radix_Wallet_Dev
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

	public func XCTAssertAllEqual(
		_ elements: some BidirectionalCollection<some Equatable>,
		file: StaticString = #filePath,
		line: UInt = #line
	) {
		guard elements.count >= 2 else { return }
		switch elements.count {
		case 0: return
		case 1: return
		case 2: XCTAssertEqual(elements.first!, elements.last!, file: file, line: line)
		default:
			let head = elements.first!
			let tail = elements.dropFirst()
			for index in tail.indices {
				let other = elements[index]
				XCTAssertEqual(
					other, head,
					"Element at \(index) not equal to first element",
					file: file, line: line
				)
			}
		}
	}

	public func XCTAssertAllEqual<Element: Equatable>(
		_ elements: some BidirectionalCollection<Element>,
		_ head: Element,
		file: StaticString = #filePath,
		line: UInt = #line
	) {
		XCTAssertAllEqual([head] + elements)
	}

	public func XCTAssertAllEqual<Element: Equatable>(
		_ elements: some BidirectionalCollection<Element>,
		_ args: Element...,
		file: StaticString = #filePath,
		line: UInt = #line
	) {
		XCTAssertAllEqual(elements + args)
	}
}
