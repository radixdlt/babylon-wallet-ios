import Foundation
@testable import Radix_Wallet_Dev
import Sargon
import XCTest

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
	let dataChannelReadyStates: AsyncStream<DataChannelReadyState>

	let receivedMessages: AsyncStream<Data>
	private let onMessageReceivedContinuation: AsyncStream<Data>.Continuation
	private let dataChannelReadyStatesContinuation: AsyncStream<DataChannelReadyState>.Continuation

	init() {
		(receivedMessages, onMessageReceivedContinuation) = AsyncStream<Data>.streamWithContinuation()
		(dataChannelReadyStates, dataChannelReadyStatesContinuation) = AsyncStream<DataChannelReadyState>.streamWithContinuation()
	}

	func receiveIncomingMessage(_ message: DataChannelClient.Message) throws {
		let data = try JSONEncoder().encode(message)
		onMessageReceivedContinuation.yield(data)
	}

	func cancel() {}

	func sendDataChannelReadyState(_ state: DataChannelReadyState) {
		dataChannelReadyStatesContinuation.yield(state)
	}
}
