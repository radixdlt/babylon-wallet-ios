import AsyncExtensions
import Foundation
@testable import RadixConnect

final class MockWebSocketClient: WebSocketClient, Sendable {
	let stateStream: AsyncStream<URLSessionWebSocketTask.State>
	let incommingMessages: AsyncThrowingStream<Data, Error>
	let sentMessages: AsyncStream<ClientMessage>

	private let sentMessagesStreamContinuation: AsyncStream<ClientMessage>.Continuation!
	private let stateStreamContinuation: AsyncStream<URLSessionWebSocketTask.State>.Continuation!
	private let messagesStreamContinuation: AsyncThrowingStream<Data, Error>.Continuation!

	lazy var sentMessagesSequence: AnyAsyncSequence<ClientMessage> = sentMessages.eraseToAnyAsyncSequence().share().eraseToAnyAsyncSequence()

	init() {
		(incommingMessages, messagesStreamContinuation) = AsyncThrowingStream<Data, Error>.streamWithContinuation()
		(sentMessages, sentMessagesStreamContinuation) = AsyncStream<ClientMessage>.streamWithContinuation()
		(stateStream, stateStreamContinuation) = AsyncStream<URLSessionWebSocketTask.State>.streamWithContinuation()
	}

	func send(message: Data) async throws {
		let msg = try JSONDecoder().decode(ClientMessage.self, from: message)
		print("__ Test: WebSocketClient mock received send request for \(msg.targetClientId)")
		sentMessagesStreamContinuation.yield(msg)
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

	func onClientMessageSent() async throws -> ClientMessage {
		await sentMessages.prefix(1).collect().first!
	}
}
