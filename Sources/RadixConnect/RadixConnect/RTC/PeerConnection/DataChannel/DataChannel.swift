import Foundation

// MARK: - DataChannel
protocol DataChannel: Sendable {
	func sendData(_ data: Data)
	func close()
}

// MARK: - DataChannelState
public enum DataChannelState: String, Sendable {
	case open, connecting, closed, closing
}

// MARK: - DataChannelDelegate
protocol DataChannelDelegate: Sendable {
	var onMessageReceived: AsyncStream<Data> { get }
	var onReadyState: AsyncStream<DataChannelState> { get }

	func cancel()
}
