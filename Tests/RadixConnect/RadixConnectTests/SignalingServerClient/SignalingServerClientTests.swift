@testable import RadixConnect
import TestingPrelude

// MARK: - SignalingClientTests
final class SignalingClientTests: TestCase {
	// MARK: - Test Values
	static let remoteClientId = RemoteClientID(rawValue: UUID().uuidString)
	static let ownClientId = RemoteClientID(rawValue: UUID().uuidString)
	static let requestId = SignalingClient.ClientMessage.RequestID(rawValue: UUID().uuidString)
	static let sdp = RTCPrimitive.SDP(rawValue: "Some sdp desc")
	static let offer = IdentifiedRTCPrimitive(content: .offer(.init(sdp: sdp)), id: remoteClientId)
	static let answer = IdentifiedRTCPrimitive(content: .answer(.init(sdp: sdp)), id: remoteClientId)
	static let iceCandidate = IdentifiedRTCPrimitive(
		content: .iceCandidate(.init(sdp: sdp,
		                             sdpMLineIndex: 32,
		                             sdpMid: "Mid")),
		id: remoteClientId
	)
	static let encryptionKey = try! SignalingClient.EncryptionKey(rawValue: .init(data: .deadbeef32Bytes))

	var jsonDecoder: JSONDecoder = {
		let decoder = JSONDecoder()
		decoder.userInfo[.clientMessageEncryptonKey] = SignalingClientTests.encryptionKey
		return decoder
	}()

	var jsonEncoder: JSONEncoder = {
		let encoder = JSONEncoder()
		encoder.userInfo[.clientMessageEncryptonKey] = SignalingClientTests.encryptionKey
		return encoder
	}()

	let webSocketClient = MockWebSocketClient()
	lazy var signalingClient = SignalingClient(encryptionKey: Self.encryptionKey,
	                                           transport: webSocketClient,
	                                           idBuilder: { Self.requestId })

	// MARK: - Outgoing Messages

	func test_sentMessagesAreInCorrectFormat_offer() throws {
		try assertSentMessageFormat(
			Self.offer,
			expectedPayload: Self.offer.content.payload
		)
	}

	func test_sentMessagesAreInCorrectFormat_answer() throws {
		try assertSentMessageFormat(
			Self.answer,
			expectedPayload: Self.answer.content.payload
		)
	}

	func testSendMessage_awaitsConfirmation() throws {
		let exp = expectation(description: "exp")
		Task {
			try await signalingClient.sendToRemote(Self.offer)
			exp.fulfill()
		}
		webSocketClient.receiveIncomingMessage(.dictionary([
			"info": .string("confirmation"),
			"requestId": .string(Self.requestId.rawValue),
		]))

		wait(for: [exp], timeout: 1.0)
	}

	// MARK: - Incoming Messages

	func test_receivedMessagesAreProperlyDecoded_remoteClientDisconnected() throws {
		let notification = SignalingClient.IncomingMessage.FromSignalingServer.Notification.remoteClientDisconnected(Self.remoteClientId)

		try assertIncomingMessageDecoding(
			msg: notification.payload,
			stream: signalingClient.onRemoteClientState,
			expected: notification
		)
	}

	func test_receivedMessagesAreProperlyDecoded_remoteClientIsAlreadyConnected() throws {
		let notification = SignalingClient.IncomingMessage.FromSignalingServer.Notification.remoteClientIsAlreadyConnected(Self.remoteClientId)

		try assertIncomingMessageDecoding(
			msg: notification.payload,
			stream: signalingClient.onRemoteClientState,
			expected: notification
		)
	}

	func test_receivedMessagesAreProperlyDecoded_remoteClientJustConnected() throws {
		let notification = SignalingClient.IncomingMessage.FromSignalingServer.Notification.remoteClientJustConnected(Self.remoteClientId)
		try assertIncomingMessageDecoding(
			msg: notification.payload,
			stream: signalingClient.onRemoteClientState,
			expected: notification
		)
	}

	func test_receivedMessagesAreProperlyDecoded_offer() throws {
		try assertIncomingPrimitiveDecoding(
			payload: Self.offer.content.payload,
			method: "offer",
			stream: signalingClient.onOffer,
			expected: IdentifiedRTCOffer(content: Self.offer.content.offer!, id: Self.offer.id)
		)
	}

	func test_receivedMessagesAreProperlyDecoded_answer() throws {
		try assertIncomingPrimitiveDecoding(
			payload: Self.answer.content.payload,
			method: "answer",
			stream: signalingClient.onAnswer,
			expected: IdentifiedRTCAnswer(content: Self.answer.content.answer!, id: Self.answer.id)
		)
	}

	func test_receivedMessagesAreProperlyDecoded_iceCandidate() throws {
		try assertIncomingPrimitiveDecoding(
			payload: Self.iceCandidate.content.payload,
			method: "iceCandidate",
			stream: signalingClient.onICECanddiate,
			expected: IdentifiedRTCICECandidate(content: Self.iceCandidate.content.iceCandidate!, id: Self.iceCandidate.id)
		)
	}

	// MARK: - Helpers

	func assertIncomingMessageDecoding<Decoded: Sendable & Equatable>(
		msg Incoming: JSONValue,
		stream: AnyAsyncSequence<Decoded>,
		expected: Decoded,
		file: StaticString = #filePath,
		line: UInt = #line
	) throws {
		let exp = expectation(description: "Wait for message")
		Task {
			let value = try await stream.first()
			XCTAssertEqual(value, expected, file: file, line: line)
			exp.fulfill()
		}
		webSocketClient.receiveIncomingMessage(Incoming)
		wait(for: [exp], timeout: 1.0)
	}

	func assertIncomingPrimitiveDecoding<Decoded: Sendable & Equatable>(
		payload: JSONValue,
		method: String,
		stream: AnyAsyncSequence<Decoded>,
		expected: Decoded,
		file: StaticString = #filePath,
		line: UInt = #line
	) throws {
		let encoded = try jsonEncoder.encode(payload)
		let encrypted = try Self.encryptionKey.encrypt(data: encoded)
		let data = JSONValue.dictionary([
			"requestId": .string(Self.requestId.rawValue),
			"method": .string(method),
			"targetClientId": .string(Self.ownClientId.rawValue),
			"encryptedPayload": .string(encrypted.hex),
		])

		let remoteData = JSONValue.dictionary([
			"info": .string("remoteData"),
			"requestId": .string(Self.requestId.rawValue),
			"remoteClientId": .string(Self.remoteClientId.rawValue),
			"data": data,
		])

		try assertIncomingMessageDecoding(
			msg: remoteData,
			stream: stream,
			expected: expected
		)
	}

	func assertSentMessageFormat(_ primitive: IdentifiedRTCPrimitive,
	                             expectedPayload: JSONValue,
	                             file: StaticString = #filePath,
	                             line: UInt = #line) throws
	{
		let exp = expectation(description: "Wait for message")
		let expectedMethod = SignalingClient.ClientMessage.Method(from: primitive.content)

		Task {
			try await signalingClient.sendToRemote(primitive)
		}

		Task {
			let sentMessage = try await webSocketClient.sentMessagesSequence.prefix(1).collect()

			let decodedMessage = try! jsonDecoder.decode(JSONValue.self, from: sentMessage.first!).dictionary!
			XCTAssertEqual(decodedMessage["requestId"], .string(Self.requestId.rawValue), file: file, line: line)
			XCTAssertEqual(decodedMessage["method"], .string(expectedMethod.rawValue), file: file, line: line)
			XCTAssertEqual(decodedMessage["targetClientId"], .string(Self.remoteClientId.rawValue), file: file, line: line)

			let encryptedPayload = try! HexCodable(hex: decodedMessage["encryptedPayload"]!.string!)
			let decryptPayload = try! Self.encryptionKey.decrypt(data: encryptedPayload.data)
			let decodedPayload = try! jsonDecoder.decode(JSONValue.self, from: decryptPayload)
			XCTAssertEqual(decodedPayload, expectedPayload, file: file, line: line)
			exp.fulfill()
		}

		wait(for: [exp], timeout: 1.0)
	}
}
