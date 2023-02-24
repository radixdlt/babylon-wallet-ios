import Foundation

// MARK: - AsyncWebSocket
public final class AsyncWebSocket: WebSocketClient {
	struct UnknownMessageReceived: Error {}

	private let url: URL
	//        private let delegate: Delegate
	private let task: URLSessionWebSocketTask
	private let session: URLSession
	// public let stateStream: AsyncStream<WebSocketState>
	public let incommingMessages: AsyncThrowingStream<Data, Error>

	public init(url: URL) {
		self.url = url
		//                var stateContinuation: AsyncStream<WebSocketState>.Continuation!
		//                self.stateStream = AsyncStream<WebSocketState> {
		//                        stateContinuation = $0
		//                }
//
		//                let delegate = Delegate(continuation: stateContinuation)
		self.session = URLSession(configuration: .default, delegate: nil, delegateQueue: .none)
		let task = self.session.webSocketTask(with: url)
		self.task = task

		self.incommingMessages = .init {
			switch try await task.receive() {
			case let .data(data):
				return data
			case let .string(string):
				return Data(string.utf8)
			@unknown default:
				throw UnknownMessageReceived()
			}
		}

		//                self.delegate = delegate
		//  delegate.continuation.yield(.connecting)
		task.resume()
		self.sendPingContinuously()
	}
}

// MARK: AsyncWebSocket.Delegate
internal extension AsyncWebSocket {
	final class Delegate: NSObject, URLSessionWebSocketDelegate, Sendable {
		//                let continuation: AsyncStream<WebSocketState>.Continuation
		//                init(continuation: AsyncStream<WebSocketState>.Continuation) {
		//                        self.continuation = continuation
		//                }
		func urlSession(
			_: URLSession,
			webSocketTask _: URLSessionWebSocketTask,
			didOpenWithProtocol protocol: String?
		) {
			//   self.continuation.yield(.connected)
		}

		func urlSession(
			_: URLSession,
			webSocketTask _: URLSessionWebSocketTask,
			didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
			reason: Data?
		) {
			//                        self.continuation.yield(.closed(closeCode.swiftify()))
			//                        self.continuation.finish()
		}
	}
}

public extension AsyncWebSocket {
	func close(with closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
		// delegate.continuation.yield(.closing)
		task.cancel(with: closeCode, reason: reason)
	}

	func send(message: Data) async throws {
		try await task.send(.data(message))
	}

	private func sendPingContinuously() {
//                Task {
//                        task.sendPing { [weak self] _ in
//                                self?.sendPingContinuously()
//                        }
//                }
	}
}
