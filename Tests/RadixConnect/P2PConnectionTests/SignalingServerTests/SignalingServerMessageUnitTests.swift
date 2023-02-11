@testable import P2PConnection
import TestingPrelude

// MARK: - SignalingServerMessageUnitTests
final class SignalingServerMessageUnitTests: TestCase {
	func testSingleValidationError() throws {
		let jsonString = """
		{
		    "info": "validationError",
		    "requestId": "deadbeef",
		    "error": [
		        {
		            "code": "invalid_type",
		            "expected": "string",
		            "received": "undefined",
		            "path": [
		                "requestId"
		            ],
		            "message": "Required"
		        },
		    ]
		}
		"""

		try doTest(json: jsonString) { messageFromSignalingServer in
			let response = try XCTUnwrap(messageFromSignalingServer.responseForRequest)
			let validationError = try XCTUnwrap(response.failure?.validationError)
			XCTAssertEqual(validationError.requestId, "deadbeef")
			let error = try XCTUnwrap(validationError.reason.array?.first)
			let errorJSONString = String(describing: error)
			XCTAssertTrue(errorJSONString.contains("invalid_type"))
			XCTAssertFalse(
				errorJSONString.contains("ValidationError"),
				"The field 'error' should not contain the whole object, but only the nested 'error' object."
			)
		}
	}

	func testMultipleValidationerror() throws {
		let jsonString = """
		{
		    "info": "validationError",
		    "requestId": "deadbeef",
		    "error": [
		        {
		            "code": "invalid_type",
		            "expected": "string",
		            "received": "undefined",
		            "path": [
		                "requestId"
		            ],
		            "message": "Required"
		        },
		        {
		            "code": "invalid_type",
		            "expected": "string",
		            "received": "undefined",
		            "path": [
		                "connectionId"
		            ],
		            "message": "Required"
		        },
		    ]
		}
		"""

		try doTest(json: jsonString) { messageFromSignalingServer in
			let response = try XCTUnwrap(messageFromSignalingServer.responseForRequest)
			let validationError = try XCTUnwrap(response.failure?.validationError)
			XCTAssertEqual(validationError.requestId, "deadbeef")
			let errors = try XCTUnwrap(validationError.reason.array)
			XCTAssertEqual(errors.count, 2)
			for error in errors {
				let errorJSONString = String(describing: error)
				XCTAssertTrue(errorJSONString.contains("invalid_type"))
				XCTAssertTrue(errorJSONString.contains("Required"))

				XCTAssertFalse(
					errorJSONString.contains("ValidationError"),
					"The field 'error' should not contain the whole object, but only the nested 'error' object."
				)
			}
			let error0 = errors[0]
			XCTAssertTrue(String(describing: error0).contains("requestId"))
			let error1 = errors[1]
			XCTAssertTrue(String(describing: error1).contains("connectionId"))
		}
	}

	func testNoRemoteClientToTalkToError() throws {
		let jsonString = """
		{
		    "info": "missingRemoteClientError",
		    "requestId": "deadbeef"
		}
		"""

		try doTest(json: jsonString) { messageFromSignalingServer in
			let response = try XCTUnwrap(messageFromSignalingServer.responseForRequest)
			let failure = try XCTUnwrap(response.failure)
			guard case let .noRemoteClientToTalkTo(requestId) = failure else {
				XCTFail("Expected Request Id")
				return
			}

			XCTAssertEqual(requestId, "deadbeef")
		}
	}

	func testRemoteClientDisconnected() throws {
		let jsonString = """
		{
		    "info": "remoteClientDisconnected"
		}
		"""

		try doTest(json: jsonString) { messageFromSignalingServer in
			let notication = try XCTUnwrap(messageFromSignalingServer.notification)

			XCTAssertEqual(notication, .remoteClientDisconnected)
		}
	}

	func testRemoteClientJustConnected() throws {
		let jsonString = """
		{
		    "info": "remoteClientJustConnected"
		}
		"""

		try doTest(json: jsonString) { messageFromSignalingServer in
			let notication = try XCTUnwrap(messageFromSignalingServer.notification)

			XCTAssertEqual(notication, .remoteClientJustConnected)
		}
	}

	func testRemoteClientIsAlreadyConnected() throws {
		let jsonString = """
		{
		    "info": "remoteClientIsAlreadyConnected"
		}
		"""

		try doTest(json: jsonString) { messageFromSignalingServer in
			let notication = try XCTUnwrap(messageFromSignalingServer.notification)

			XCTAssertEqual(notication, .remoteClientIsAlreadyConnected)
		}
	}

	func testInvalidMessageError() throws {
		let jsonString = """
		{
		    "info": "invalidMessageError",
		    "error": "invalid message format",
		    "data": {
		        "requestId": "deadbeef",
		        "encryptedPayload": "fadebeef",
		        "connectionId": "deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef",
		        "method": "offer",
		        "source": "wallet"
		    }
		}
		"""

		try doTest(json: jsonString) { messageFromSignalingServer in
			let response = try XCTUnwrap(messageFromSignalingServer.responseForRequest)
			let failure = try XCTUnwrap(response.failure)
			let invalidMessageError = try XCTUnwrap(failure.invalidMessageError)
			let sent = invalidMessageError.messageSentThatWasInvalid
			XCTAssertEqual(sent.requestId, "deadbeef")
			XCTAssertEqual(sent.encryptedPayload, "fadebeef")
			XCTAssertEqual(sent.connectionID, .deadbeef32Bytes)
			XCTAssertEqual(sent.method, .offer)
			XCTAssertEqual(invalidMessageError.reason, .string("invalid message format"))
		}
	}

	func testReceivedRemoteData() throws {
		let jsonString = """
		{
		  "requestId" : "a245f246-2891-4a18-bad4-276fde77d8a1",
		  "info" : "remoteData",
		  "data" : {
		    "encryptedPayload" : "22a187fd767111ff9f28403195278151b7eb32e95753cfe65738e201acaa852c1d91388c58f2fd4a2f17c6092ab1f07a498d50706a6e5638fd7fb3e0a8e928db4614b941b68de0acfc1b0a2c3ca7f20c69f96824437635645830ca73b3f27612418ac84c19ad662a6caccada07d23f5e294290d8249bf65d876f4f5c27a75212bda6d9cbdc77505266ee2f3b0cfc318c605b04fe4eb28118a163a05be0631afcc52a57bd03b9ac433d42919e240001d9d41806056398c060890b1434d1f4f166226f2286ec52c36b47b205a512abb518eeb899484b6c919cf7ea3edc4205a95c2858984bcf4f10384924ce1f35eb5007a7e08d21f9a837e87f559da3ba765f2f2389d7da65ba5df1c0c40442da787bef4a456a22ab7b32ad3ab70736e8b41d4b75b1ac3526f129bec83b29b0d810959fbacef3f33d90e8b21ece89255b424d3ee7dd5e233dffa33eb8230b6b1af0bcd94d3d41f1d569e939f2815875e515f98f0ebaa0456e0b8811653208cf66c599aff88b1c03e2cd5cde3cad8a0e29bcf3b7283114ac284496c84fd49886cb3009772cb049be491ac94a961d643c2a42162520840e7af6ab7c794af73eedaf0476ef01750be8da25d682ce43075b83ffdca015069f5b4cbee7c0b0653d4abcb1318581f6e4db1500e0fda3896699b72471e9bee0c5bf45b311fa4e982eede26f94d2f58cabd8a2a44db1719144868a10b8f616145f63c28bb6f69f6144162803a5a6c3",
		    "connectionId" : "f961b9e7262bb91291a349d11bdb28fcac71bee339a1ee26caade3049be41b8e",
		    "requestId" : "a245f246-2891-4a18-bad4-276fde77d8a1",
		    "method" : "answer",
		    "source" : "extension"
		  }
		}
		"""

		try doTest(json: jsonString) { messageFromSignalingServer in
			let fromRemoteClientOriginally = try XCTUnwrap(messageFromSignalingServer.fromRemoteClientOriginally)
			XCTAssertEqual(fromRemoteClientOriginally.method, .answer)
			XCTAssertEqual(fromRemoteClientOriginally.source, .browserExtension)
			XCTAssertEqual(fromRemoteClientOriginally.connectionID, try .init(data: .init(hex: "f961b9e7262bb91291a349d11bdb28fcac71bee339a1ee26caade3049be41b8e")))
			XCTAssertEqual(fromRemoteClientOriginally.requestId, "a245f246-2891-4a18-bad4-276fde77d8a1")
		}
	}
}

extension SignalingServerMessageUnitTests {
	private func doTest(
		json jsonString: String,
		assert: (SignalingServerMessage.Incoming) throws -> Void
	) throws {
		let json = jsonString.data(using: .utf8)!
		let jsonDecoder = JSONDecoder()

		let messageFromSignalingServer = try jsonDecoder.decode(SignalingServerMessage.Incoming.self, from: json)

		try assert(messageFromSignalingServer)
	}
}
