import AsyncExtensions
import Foundation
@testable import RadixConnect
import TestingPrelude

final class MockWebSocketClient: SignalingTransport, Sendable {
	var incomingMessages: AsyncStream<Data>

	func cancel() {}

	let stateStream: AsyncStream<URLSessionWebSocketTask.State>
	private let sentMessages: AsyncStream<Data>

	private let sentMessagesStreamContinuation: AsyncStream<Data>.Continuation!
	private let stateStreamContinuation: AsyncStream<URLSessionWebSocketTask.State>.Continuation!
	private let messagesStreamContinuation: AsyncStream<Data>.Continuation!

	lazy var sentMessagesSequence: AnyAsyncSequence<Data> = sentMessages.eraseToAnyAsyncSequence().share().eraseToAnyAsyncSequence()

	init() {
		(incomingMessages, messagesStreamContinuation) = AsyncStream<Data>.streamWithContinuation()
		(sentMessages, sentMessagesStreamContinuation) = AsyncStream<Data>.streamWithContinuation()
		(stateStream, stateStreamContinuation) = AsyncStream<URLSessionWebSocketTask.State>.streamWithContinuation()
	}

	func send(message: Data) async throws {
		sentMessagesStreamContinuation.yield(message)
	}

	nonisolated func close(with closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {}

	nonisolated func open() {}

	// MARK: - Helpers

	func receiveIncomingMessage(_ msg: JSONValue) {
		let encoded = try! JSONEncoder().encode(msg)
		messagesStreamContinuation.yield(encoded)
	}

	func respondToRequest(message: SignalingClient.IncomingMessage.FromSignalingServer.ResponseForRequest) {
		receiveIncomingMessage(message.json)
	}

	func onClientMessageSent() async throws -> Data {
		try await sentMessagesSequence.first()
	}
}
