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
	let receivedMessages: AsyncStream<Data>
	private let onMessageReceivedContinuation: AsyncStream<Data>.Continuation

	init() {
		(receivedMessages, onMessageReceivedContinuation) = AsyncStream<Data>.streamWithContinuation()
	}

        func receiveIncommingMessage(_ message: DataChannelClient.Message) throws {
		let data = try JSONEncoder().encode(message)
		onMessageReceivedContinuation.yield(data)
	}

        func cancel() {}
}
