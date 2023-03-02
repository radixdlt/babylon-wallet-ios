import Foundation
@testable import RadixConnect

// MARK: - DataChannelMock
final class DataChannelMock: DataChannel {
	let sentData: AsyncStream<Data>
	private let sentDataContinuation: AsyncStream<Data>.Continuation

	init() {
		(sentData, sentDataContinuation) = AsyncStream<Data>.streamWithContinuation()
	}

	func sendData(_ data: Data) {
		sentDataContinuation.yield(data)
	}

	func close() {}
}

// MARK: - DataChannelDelegateMock
final class DataChannelDelegateMock: DataChannelDelegate, Sendable {
	func cancel() {}

	let onMessageReceived: AsyncStream<Data>
	let onReadyState: AsyncStream<DataChannelState>

	private let onMessageReceivedContinuation: AsyncStream<Data>.Continuation
	private let onReadyStateContinuation: AsyncStream<DataChannelState>.Continuation

	init() {
		(onMessageReceived, onMessageReceivedContinuation) = AsyncStream<Data>.streamWithContinuation()
		(onReadyState, onReadyStateContinuation) = AsyncStream<DataChannelState>.streamWithContinuation()
	}

	func receiveIncommingMessage(_ message: DataChannelMessage) throws {
		let data = try JSONEncoder().encode(message)
		onMessageReceivedContinuation.yield(data)
	}
}
