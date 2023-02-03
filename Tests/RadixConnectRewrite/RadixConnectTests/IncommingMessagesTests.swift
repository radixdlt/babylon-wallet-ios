//@testable import SignalingClient
//import TestingPrelude
//
//class IncommingMessagesTests: TestCase {
//	let requestId = RequestID(rawValue: UUID().uuidString)
//
//        // MARK: - Signaling server message tests
//
//	func test_signalingServerMessage_remoteClientDisconnected() throws {
//		try assertNotificationDecoding(
//			of: .dictionary([
//				"info": .string("remoteClientDisconnected"),
//			]),
//			expected: .remoteClientDisconnected
//		)
//	}
//
//        func test_signalingServerMessage_remoteClientIsAlreadyConnected() throws {
//                try assertNotificationDecoding(
//                        of: .dictionary([
//                                "info": .string("remoteClientIsAlreadyConnected"),
//                        ]),
//                        expected: .remoteClientIsAlreadyConnected
//                )
//        }
//
//        func test_signalingServerMessage_remoteClientJustConnected() throws {
//                try assertNotificationDecoding(
//                        of: .dictionary([
//                                "info": .string("remoteClientJustConnected"),
//                        ]),
//                        expected: .remoteClientJustConnected
//                )
//        }
//
//        func test_signalingServerMessage_requestConfirmation_success() throws {
//                try assertRequestConfirmationDecoding(
//                        of: .dictionary([
//                                "info": .string("confirmation"),
//                                "requestId": .string(requestId.rawValue),
//                        ]),
//                        expected: .success(requestId)
//                )
//        }
//
//        func test_signalingServerMessage_requestConfirmation_missingRemoteClientError() throws {
//                try assertRequestConfirmationDecoding(
//                        of: .dictionary([
//                                "info": .string("missingRemoteClientError"),
//                                "requestId": .string(requestId.rawValue),
//                        ]),
//                        expected: .failure(.noRemoteClientToTalkTo(requestId))
//                )
//        }
//
//        func test_signalingServerMessage_requestConfirmation_invalidMessageError() throws {
//                let error = JSONValue.string("invalid message format, expected JSON")
//                let message = ClientMessage(
//                        requestId: requestId,
//                        method: .offer,
//                        source: .extension,
//                        connectionId: "connectionId",
//                        encryptedPayload: "somePayload")
//
//                try assertRequestConfirmationDecoding(
//                        of: .dictionary([
//                                "info": .string("invalidMessageError"),
//                                "error": error,
//                                "data": .dictionary([
//                                        "requestId": .string(requestId.rawValue),
//                                        "method": .string(message.method.rawValue),
//                                        "source": .string(message.source.rawValue),
//                                        "connectionId": .string(message.connectionId),
//                                        "encryptedPayload": .string(message.encryptedPayload.rawValue),
//                                ]),
//                        ]),
//                        expected: .failure(.invalidMessageError(
//                                .init(reason: error, messageSentThatWasInvalid: message)
//                        ))
//                )
//        }
//
//        func test_signalingServerMessage_requestConfirmation_validationError() throws {
//                let error = JSONValue.string("Some Error")
//                try assertRequestConfirmationDecoding(
//                        of: .dictionary([
//                                "info": .string("validationError"),
//                                "requestId": .string(requestId.rawValue),
//                                "error": error,
//                        ]),
//                        expected: .failure(.validationError(.init(reason: error, requestId: requestId)))
//                )
//        }
//
//        // MARK: - Remote Client tests
//
//        func test_remoteClientMessage_offer() throws {
//                try assertClientMessageForMethodDecoding(
//                        of: "offer",
//                        expected: .init(withMethod: .offer))
//        }
//
//        func test_remoteClientMessage_answer() throws {
//                try assertClientMessageForMethodDecoding(
//                        of: "answer",
//                        expected: .init(withMethod: .answer))
//        }
//
//        func test_remoteClientMessage_iceCandidate() throws {
//                try assertClientMessageForMethodDecoding(
//                        of: "iceCandidate",
//                        expected: .init(withMethod: .iceCandidate))
//        }
//
//        private func assertClientMessageForMethodDecoding(
//                of method: String,
//                expected: ClientMessage,
//                file: StaticString = #filePath,
//                line: UInt = #line) throws {
//                let raw = JSONValue.dictionary([
//                        "requestId": .string(expected.requestId.rawValue),
//                        "method": .string(method),
//                        "source": .string(expected.source.rawValue),
//                        "connectionId": .string(expected.connectionId),
//                        "encryptedPayload": .string(expected.encryptedPayload.rawValue),
//                ])
//
//                try assertClientMessageDecoding(of: raw,
//                                            expected: expected,
//                                                file: file, line: line)
//        }
//
//        private func assertClientMessageDecoding(
//                of json: JSONValue,
//                expected: ClientMessage,
//                file: StaticString = #filePath,
//                line: UInt = #line
//        ) throws {
//                let decoded = try JSONDecoder().decode(ClientMessage.self,
//                                                       from: try JSONEncoder().encode(json))
//                XCTAssertEqual(expected, decoded, file: file, line: line)
//        }
//
//        // MARK: - Private
//
//	private func assertDecoding(
//                of json: JSONValue,
//                expected: IncommingMessage,
//                file: StaticString = #filePath,
//                line: UInt = #line) throws {
//		let decoded = try JSONDecoder().decode(IncommingMessage.self,
//		                                       from: try JSONEncoder().encode(json))
//		XCTAssertEqual(expected, decoded, file: file, line: line)
//	}
//
//        private func assertNotificationDecoding(
//                of json: JSONValue,
//                expected: IncommingMessage.FromSignalingServer.Notification,
//                file: StaticString = #filePath,
//                line: UInt = #line) throws {
//                try assertDecoding(
//                        of: json,
//                        expected: .fromSignalingServer(.notification(expected)),
//                        file: file,
//                        line: line
//                )
//        }
//
//        private func assertRequestConfirmationDecoding(
//                of json: JSONValue,
//                expected: IncommingMessage.FromSignalingServer.ResponseForRequest,
//                file: StaticString = #filePath,
//                line: UInt = #line) throws {
//                try assertDecoding(
//                        of: json,
//                        expected: .fromSignalingServer(.responseForRequest(expected)),
//                        file: file,
//                        line: line
//                )
//        }
//}
//
//extension ClientMessage {
//        init(withMethod method: Method) {
//                self.init(requestId: .init(UUID().uuidString),
//                          method: method,
//                          source: .extension,
//                          connectionId: UUID().uuidString,
//                          encryptedPayload: "somePayload")
//        }
//}
