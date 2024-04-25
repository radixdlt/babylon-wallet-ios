@testable import Radix_Wallet_Dev
import Sargon
import XCTest

// MARK: - SignalingClientTests
final class SignalingClientTests: TestCase {
	// MARK: - Test Values
	static let remoteClientId = RemoteClientID(rawValue: UUID().uuidString)
	static let ownClientId = RemoteClientID(rawValue: UUID().uuidString)

	static let requestId = SignalingClient.ClientMessage.RequestID(
		rawValue: UUID().uuidString
	)

	static let sdp = RTCPrimitive.SDP(rawValue: "Some sdp desc")

	static let offer = IdentifiedRTCPrimitive(
		.offer(.init(sdp: sdp)),
		id: remoteClientId
	)

	static let answer = IdentifiedRTCPrimitive(
		.answer(.init(sdp: sdp)),
		id: remoteClientId
	)

	static let iceCandidate = IdentifiedRTCPrimitive(
		.iceCandidate(.init(
			sdp: sdp,
			sdpMLineIndex: 32,
			sdpMid: "Mid"
		)),
		id: remoteClientId
	)

	static let encryptionKey = try! SignalingClient.EncryptionKey(rawValue: .sample)

	var jsonDecoder: JSONDecoder = {
		let decoder = JSONDecoder()
		decoder.userInfo[.clientMessageEncryptionKey] = SignalingClientTests.encryptionKey
		return decoder
	}()

	var jsonEncoder: JSONEncoder = {
		let encoder = JSONEncoder()
		encoder.userInfo[.clientMessageEncryptionKey] = SignalingClientTests.encryptionKey
		return encoder
	}()

	let webSocketClient = MockWebSocketClient()
	lazy var signalingClient = SignalingClient(
		encryptionKey: Self.encryptionKey,
		transport: webSocketClient,
		idBuilder: { Self.requestId }
	)

	// MARK: - Outgoing Messages

	func test_sentMessagesAreInCorrectFormat_offer() async throws {
		try await assertSentMessageFormat(
			Self.offer,
			expectedPayload: Self.offer.value.payload
		)
	}

	func test_sentMessagesAreInCorrectFormat_answer() async throws {
		try await assertSentMessageFormat(
			Self.answer,
			expectedPayload: Self.answer.value.payload
		)
	}

	func testSendMessage_awaitsConfirmation() async throws {
		let exp = expectation(description: "exp")
		Task {
			try await signalingClient.sendToRemote(Self.offer)
			exp.fulfill()
		}
		webSocketClient.receiveIncomingMessage(.dictionary([
			"info": .string("confirmation"),
			"requestId": .string(Self.requestId.rawValue),
		]))

		await fulfillment(of: [exp], timeout: 0.5)
	}

	// MARK: - Incoming Messages

	func test_receivedMessagesAreProperlyDecoded_remoteClientDisconnected() async throws {
		let notification = SignalingClient.IncomingMessage.FromSignalingServer.Notification.remoteClientDisconnected(Self.remoteClientId)

		try await assertIncomingMessageDecoding(
			msg: notification.payload,
			stream: signalingClient.onRemoteClientState,
			expected: notification
		)
	}

	func test_receivedMessagesAreProperlyDecoded_remoteClientIsAlreadyConnected() async throws {
		let notification = SignalingClient.IncomingMessage.FromSignalingServer.Notification.remoteClientIsAlreadyConnected(Self.remoteClientId)

		try await assertIncomingMessageDecoding(
			msg: notification.payload,
			stream: signalingClient.onRemoteClientState,
			expected: notification
		)
	}

	func test_receivedMessagesAreProperlyDecoded_remoteClientJustConnected() async throws {
		let notification = SignalingClient.IncomingMessage.FromSignalingServer.Notification.remoteClientJustConnected(Self.remoteClientId)
		try await assertIncomingMessageDecoding(
			msg: notification.payload,
			stream: signalingClient.onRemoteClientState,
			expected: notification
		)
	}

	func test_receivedMessagesAreProperlyDecoded_offer() async throws {
		try await assertIncomingPrimitiveDecoding(
			payload: Self.offer.value.payload,
			method: "offer",
			stream: signalingClient.onOffer,
			expected: IdentifiedRTCOffer(
				Self.offer.value.offer!,
				id: Self.offer.id
			)
		)
	}

	func test_receivedMessagesAreProperlyDecoded_answer() async throws {
		try await assertIncomingPrimitiveDecoding(
			payload: Self.answer.value.payload,
			method: "answer",
			stream: signalingClient.onAnswer,
			expected: IdentifiedRTCAnswer(
				Self.answer.value.answer!,
				id: Self.answer.id
			)
		)
	}

	func test_receivedMessagesAreProperlyDecoded_iceCandidate() async throws {
		try await assertIncomingPrimitiveDecoding(
			payload: Self.iceCandidate.value.payload,
			method: "iceCandidate",
			stream: signalingClient.onICECanddiate,
			expected: IdentifiedRTCICECandidate(
				Self.iceCandidate.value.iceCandidate!,
				id: Self.iceCandidate.id
			)
		)
	}

	// MARK: - Helpers

	func assertIncomingMessageDecoding<Decoded: Sendable & Equatable>(
		msg Incoming: JSONValue,
		stream: AnyAsyncSequence<Decoded>,
		expected: Decoded,
		file: StaticString = #filePath,
		line: UInt = #line
	) async throws {
		let exp = expectation(description: "Wait for message")
		Task {
			let value = try await stream.first()
			XCTAssertEqual(value, expected, file: file, line: line)
			exp.fulfill()
		}
		webSocketClient.receiveIncomingMessage(Incoming)
		await fulfillment(of: [exp], timeout: 0.5)
	}

	func assertIncomingPrimitiveDecoding<Decoded: Sendable & Equatable>(
		payload: JSONValue,
		method: String,
		stream: AnyAsyncSequence<Decoded>,
		expected: Decoded,
		file: StaticString = #filePath,
		line: UInt = #line
	) async throws {
		let encoded = try jsonEncoder.encode(payload)
		let encrypted = try EncryptionScheme.version1.encrypt(data: encoded, encryptionKey: Self.encryptionKey.symmetric)
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

		try await assertIncomingMessageDecoding(
			msg: remoteData,
			stream: stream,
			expected: expected
		)
	}

	func assertSentMessageFormat(
		_ primitive: IdentifiedRTCPrimitive,
		expectedPayload: JSONValue,
		file: StaticString = #filePath,
		line: UInt = #line
	) async throws {
		let exp = expectation(description: "Wait for message")
		let expectedMethod = SignalingClient.ClientMessage.Method(from: primitive.value)

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
			let decryptedPayload = try EncryptionScheme.version1.decrypt(data: encryptedPayload.data, decryptionKey: Self.encryptionKey.symmetric)
			let decodedPayload = try! jsonDecoder.decode(JSONValue.self, from: decryptedPayload)
			XCTAssertEqual(decodedPayload, expectedPayload, file: file, line: line)
			exp.fulfill()
		}

		await fulfillment(of: [exp], timeout: 1.0)
	}
}
