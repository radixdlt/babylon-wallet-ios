import Foundation

protocol DataChannel: Sendable {
        func sendData(_ data: Data)
        func close()
}

public enum DataChannelState: String, Sendable {
        case open, connecting, closed, closing
}

protocol DataChannelDelegate: Sendable {
        var onMessageReceived: AsyncStream<Data> { get }
        var onReadyState: AsyncStream<DataChannelState> { get }
}
