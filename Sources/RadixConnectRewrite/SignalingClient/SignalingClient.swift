protocol WebSocketClient: Sendable {
        var stateStream: AsyncStream<WebSocketState> { get }
        var incomingMessageStream: AsyncThrowingStream<Data, Error> { get }

        func send(message: Data) async throws
        func close(with closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?)
}
