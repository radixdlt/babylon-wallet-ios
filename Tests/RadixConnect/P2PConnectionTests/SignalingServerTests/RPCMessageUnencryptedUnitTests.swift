@testable import P2PConnection
import TestingPrelude

// MARK: - RPCMessageUnencryptedUnitTests
final class RPCMessageUnencryptedUnitTests: XCTestCase {
	func testJSONEncodingRPCMessage() throws {
		let unencryptedMessage = RPCMessageUnencrypted(
			method: .answer,
			source: .mobileWallet,
			connectionId: .deadbeef32Bytes,
			requestId: .deadbeef32Bytes,
			unencryptedPayload: .deadbeef32Bytes
		)
		let mockedEncryption = "mocked encrypted".data(using: .utf8)!
		let rpcMessage = RPCMessage(
			encryption: mockedEncryption,
			of: unencryptedMessage
		)
		let jsonEncoder = JSONEncoder()
		XCTAssertNoThrow(try jsonEncoder.encode(rpcMessage))
	}

	func testJSONDecodingRPCMessage1() throws {
		let json = """
		{
		    "encryptedPayload" : "6d6f636b656420656e63727970746564",
		    "connectionId" : "deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef",
		    "requestId" : "deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef",
		    "method" : "answer",
		    "source" : "wallet"
		}
		""".data(using: .utf8)!
		let jsonDecoder = JSONDecoder()
		let rpcMessage = try jsonDecoder.decode(RPCMessage.self, from: json)
		XCTAssertEqual(rpcMessage.source, .mobileWallet)
		XCTAssertEqual(rpcMessage.method, .answer)
	}

	func testJSONDecodingRPCMessage2() throws {
		let json = """
		{
		    "encryptedPayload" : "6d6f636b656420656e63727970746564",
		    "connectionId" : "deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef",
		    "requestId" : "deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef",
		    "method" : "answer",
		    "source" : "wallet"
		}
		""".data(using: .utf8)!
		let jsonDecoder = JSONDecoder()
		let rpcMessage = try jsonDecoder.decode(RPCMessage.self, from: json)
		XCTAssertEqual(rpcMessage.source, .mobileWallet)
		XCTAssertEqual(rpcMessage.method, .answer)
	}

	func testVectors() throws {
		try testFixture(
			json: "RPCMessageVectors"
		) { (messages: [RPCMessage]) in
			XCTAssertGreaterThan(messages.count, 0)
			messages.forEach { rpcMessage in
				XCTAssertFalse(rpcMessage.requestId.isEmpty)
			}
		}
	}
}

//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftCrypto open source project
//
// Copyright (c) 2019-2022 Apple Inc. and the SwiftCrypto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.md for the list of SwiftCrypto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
public extension XCTestCase {
	func testFixture<T: Decodable>(
		json: String,
		file: StaticString = #file,
		line: UInt = #line,
		testFunction: (T) throws -> Void
	) throws {
		let fileDirectory = URL(
			fileURLWithPath: "\(file)"
		)

		let testsDirectory = fileDirectory
			.pathComponents
			.dropLast(1)
			.joined(separator: "/")

		let fileURL = try XCTUnwrap(URL(fileURLWithPath: "\(testsDirectory)/TestVectors/\(json).json"), file: file, line: line)

		let data = try Data(contentsOf: fileURL)

		let decoder = JSONDecoder()
		let test = try decoder.decode(T.self, from: data)

		try testFunction(test)
	}
}
