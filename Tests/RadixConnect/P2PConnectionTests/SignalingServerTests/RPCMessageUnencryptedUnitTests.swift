@testable import P2PConnection
import SharedTestingModels
import TestingPrelude

// MARK: - RPCMessageUnencryptedUnitTests
final class RPCMessageUnencryptedUnitTests: TestCase {
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
			bundle: .module,
			jsonName: "RPCMessageVectors"
		) { (messages: [RPCMessage]) in
			XCTAssertGreaterThan(messages.count, 0)
			messages.forEach { rpcMessage in
				XCTAssertFalse(rpcMessage.requestId.isEmpty)
			}
		}
	}
}
