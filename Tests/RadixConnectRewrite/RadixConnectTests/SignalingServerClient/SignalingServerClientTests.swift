// import Models
@testable import RadixConnect
import TestingPrelude

//// MARK: - SignalingClientTests
// final class SignalingClientTests: TestCase {
//	// MARK: - Test Values
//	static let remoteClientId = ClientID(rawValue: UUID().uuidString)
//	static let ownClientId = ClientID(rawValue: UUID().uuidString)
//	static let requestId = RequestID(rawValue: UUID().uuidString)
//	static let sdp = SDP(rawValue: "Some sdp desc")
//	static let offer = IdentifiedPrimitive(content: RTCPrimitive.Offer(sdp: sdp), id: remoteClientId)
//	static let answer = IdentifiedPrimitive(content: RTCPrimitive.Answer(sdp: sdp), id: remoteClientId)
//	static let iceCandidate = IdentifiedPrimitive(content: RTCPrimitive.ICECandidate(sdp: sdp,
//	                                                                                 sdpMLineIndex: 32,
//	                                                                                 sdpMid: "Mid"),
//	                                              id: remoteClientId)
//	static let connectionID = try! SignalingServerConnectionID(.init(.deadbeef32Bytes))
//	static let encryptionKey = try! EncryptionKey(rawValue: .init(data: .deadbeef32Bytes))
//
//	let webSocketClient = MockWebSocketClient()
//	lazy var signalingClient = SignalingClient(encryptionKey: Self.encryptionKey,
//	                                           webSocketClient: webSocketClient,
//	                                           connectionID: Self.connectionID,
//	                                           idBuilder: { Self.requestId },
//	                                           ownClientId: Self.ownClientId)
//
//	// MARK: - Outgoing Messages
//
//	func test_sentMessagesAreInCorrectFormat_offer() throws {
//		try assertSentMessageFormat(
//			.offer(Self.offer),
//			expectedPayload: Self.offer.content.payload
//		)
//	}
//
//	func test_sentMessagesAreInCorrectFormat_answer() throws {
//		try assertSentMessageFormat(
//			.answer(Self.answer),
//			expectedPayload: Self.answer.content.payload
//		)
//	}
//
//	//        func test_sentMessagesAreInCorrectFormat_ICECandidate() throws {
//	//                try assertSentMessageFormat(
//	//                        .addICE(Self.iceCandidate),
//	//                        expectedPayload: Self.iceCandidate.payload
//	//                )
//	//        }
//
//	func testSendMessage_awaitsConfirmation() throws {
//		let exp = expectation(description: "exp")
//		Task {
//			try await signalingClient.sendToRemote(rtcPrimitive: .offer(Self.offer))
//			exp.fulfill()
//		}
//		webSocketClient.receiveIncommingMessage(.dictionary([
//			"info": .string("confirmation"),
//			"requestId": .string(Self.requestId.rawValue),
//		]))
//
//		wait(for: [exp], timeout: 1.0)
//	}
//
//	// MARK: - Incomming Messages
//
//	func test_receivedMessagesAreProperlyDecoded_remoteClientDisconnected() throws {
//		let notification = IncommingMessage.FromSignalingServer.Notification.remoteClientDisconnected(Self.remoteClientId)
//
//		try assertIncommingMessageDecoding(
//			msg: notification.payload,
//			stream: signalingClient.onRemoteClientState,
//			expected: notification
//		)
//	}
//
//	func test_receivedMessagesAreProperlyDecoded_remoteClientIsAlreadyConnected() throws {
//		let notification = IncommingMessage.FromSignalingServer.Notification.remoteClientIsAlreadyConnected(Self.remoteClientId)
//
//		try assertIncommingMessageDecoding(
//			msg: notification.payload,
//			stream: signalingClient.onRemoteClientState,
//			expected: notification
//		)
//	}
//
//	func test_receivedMessagesAreProperlyDecoded_remoteClientJustConnected() throws {
//		let notification = IncommingMessage.FromSignalingServer.Notification.remoteClientJustConnected(Self.remoteClientId)
//		try assertIncommingMessageDecoding(
//			msg: notification.payload,
//			stream: signalingClient.onRemoteClientState,
//			expected: notification
//		)
//	}
//
//	func test_receivedMessagesAreProperlyDecoded_offer() throws {
//		try assertIncommingPrimitiveDecoding(
//			payload: Self.offer.content.payload,
//			method: "offer",
//			stream: signalingClient.onOffer,
//			expected: Self.offer
//		)
//	}
//
//	func test_receivedMessagesAreProperlyDecoded_answer() throws {
//		try assertIncommingPrimitiveDecoding(
//			payload: Self.answer.content.payload,
//			method: "answer",
//			stream: signalingClient.onAnswer,
//			expected: Self.answer
//		)
//	}
//
//	func test_receivedMessagesAreProperlyDecoded_iceCandidate() throws {
//		try assertIncommingPrimitiveDecoding(
//			payload: Self.iceCandidate.content.payload,
//			method: "iceCandidate",
//			stream: signalingClient.onICECanddiate,
//			expected: Self.iceCandidate
//		)
//	}
//
//	// MARK: - Helpers
//
//	func assertIncommingMessageDecoding<Decoded: Sendable & Equatable>(
//		msg incomming: JSONValue,
//		stream: AnyAsyncSequence<Decoded>,
//		expected: Decoded,
//		file: StaticString = #filePath,
//		line: UInt = #line
//	) throws {
//		let exp = expectation(description: "Wait for message")
//		Task {
//			let value = try await stream.prefix(1).collect().first!
//			XCTAssertEqual(value, expected, file: file, line: line)
//			exp.fulfill()
//		}
//		webSocketClient.receiveIncommingMessage(incomming)
//		wait(for: [exp], timeout: 1.0)
//	}
//
//	func assertIncommingPrimitiveDecoding<Decoded: Sendable & Equatable>(
//		payload: JSONValue,
//		method: String,
//		stream: AnyAsyncSequence<Decoded>,
//		expected: Decoded,
//		file: StaticString = #filePath,
//		line: UInt = #line
//	) throws {
//		let encoded = try JSONEncoder().encode(payload)
//		let encrypted = try Self.encryptionKey.encrypt(data: encoded)
//		let data = JSONValue.dictionary([
//			"requestId": .string(Self.requestId.rawValue),
//			"method": .string(method),
//			"source": .string("extension"),
//			"sourceClientId": .string(Self.remoteClientId.rawValue),
//			"targetClientId": .string(Self.ownClientId.rawValue),
//			"connectionId": .string(Self.connectionID.rawValue.data.hex()),
//			"encryptedPayload": .string(encrypted.hex),
//		])
//
//		let remoteData = JSONValue.dictionary([
//			"info": .string("remoteData"),
//			"requestId": .string(Self.requestId.rawValue),
//			"data": data,
//		])
//
//		try assertIncommingMessageDecoding(
//			msg: remoteData,
//			stream: stream,
//			expected: expected
//		)
//	}
//
//	func assertSentMessageFormat(_ primitive: RTCPrimitive,
//	                             expectedPayload: JSONValue,
//	                             file: StaticString = #filePath,
//	                             line: UInt = #line) throws
//	{
//		let exp = expectation(description: "Wait for message")
//		let expectedMethod = ClientMessage.Method(from: primitive)
//
//		Task {
//			try await signalingClient.sendToRemote(rtcPrimitive: primitive)
//		}
//
//		Task {
//			let sentMessage = await webSocketClient.sentMessagesStream.prefix(1).collect()
//
//			let decodedMessage = try! JSONDecoder().decode(JSONValue.self, from: sentMessage.first!).dictionary!
//			XCTAssertEqual(decodedMessage["requestId"], .string(Self.requestId.rawValue), file: file, line: line)
//			XCTAssertEqual(decodedMessage["method"], .string(expectedMethod.rawValue), file: file, line: line)
//			XCTAssertEqual(decodedMessage["source"], .string("wallet"), file: file, line: line)
//			XCTAssertEqual(decodedMessage["connectionId"], .string(.deadbeef32Bytes), file: file, line: line)
//
//			let encryptedPayload = try! EncryptedPayload(rawValue: .init(hex: decodedMessage["encryptedPayload"]!.string!))
//			let decryptPayload = try! Self.encryptionKey.decrypt(data: encryptedPayload.data)
//			let decodedPayload = try! JSONDecoder().decode(JSONValue.self, from: decryptPayload)
//			XCTAssertEqual(decodedPayload, expectedPayload, file: file, line: line)
//			exp.fulfill()
//		}
//
//		wait(for: [exp], timeout: 1.0)
//	}
// }
