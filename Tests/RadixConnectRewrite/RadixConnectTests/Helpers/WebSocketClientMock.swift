import AsyncExtensions
import Foundation
@testable import RadixConnect

final class MockWebSocketClient: SignalingTransport, Sendable {
	let stateStream: AsyncStream<URLSessionWebSocketTask.State>
	let incommingMessages: AsyncThrowingStream<Data, Error>
	private let sentMessages: AsyncStream<Data>

	private let sentMessagesStreamContinuation: AsyncStream<Data>.Continuation!
	private let stateStreamContinuation: AsyncStream<URLSessionWebSocketTask.State>.Continuation!
	private let messagesStreamContinuation: AsyncThrowingStream<Data, Error>.Continuation!

	lazy var sentMessagesSequence: AnyAsyncSequence<Data> = sentMessages.eraseToAnyAsyncSequence().share().eraseToAnyAsyncSequence()

	init() {
		(incommingMessages, messagesStreamContinuation) = AsyncThrowingStream<Data, Error>.streamWithContinuation()
		(sentMessages, sentMessagesStreamContinuation) = AsyncStream<Data>.streamWithContinuation()
		(stateStream, stateStreamContinuation) = AsyncStream<URLSessionWebSocketTask.State>.streamWithContinuation()
	}

	func send(message: Data) async throws {
		sentMessagesStreamContinuation.yield(message)
	}

	nonisolated func close(with closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {}

	nonisolated func open() {}

	// MARK: - Helpers

	func receiveIncommingMessage(_ msg: JSONValue) {
		let encoded = try! JSONEncoder().encode(msg)
		messagesStreamContinuation.yield(encoded)
	}

	func respondToRequest(message: IncommingMessage.FromSignalingServer.ResponseForRequest) {
		receiveIncommingMessage(message.json)
	}

	func onClientMessageSent() async throws -> Data {
		try await sentMessagesSequence.prefix(1).collect().first!
	}
}
