import Foundation

// MARK: - AsyncWebSocket
public final class AsyncWebSocket: NSObject, WebSocketClient {
	struct UnknownMessageReceived: Error {}

	private let url: URL
	//        private let delegate: Delegate
	private var task: URLSessionWebSocketTask?
	private lazy var session: URLSession = {
		var config = URLSessionConfiguration.default
		config.waitsForConnectivity = true
		let delegate = Delegate { [weak self] in
			self?.task?.cancel()
			self?.task = nil
		}
		return URLSession(configuration: config, delegate: delegate, delegateQueue: .none)
	}()

	// public let stateStream: AsyncStream<WebSocketState>
	public let incommingMessages: AsyncStream<Data>
	private let incommingMessagesContinuation: AsyncStream<Data>.Continuation

	public init(url: URL) {
		self.url = url

		(incommingMessages, incommingMessagesContinuation) = AsyncStream.streamWithContinuation()

//		self.sendPingContinuously()
		super.init()
		receiveMessages()
	}

	func receiveMessages() {
		webSocketTask().receive { [weak self] result in
			let message = try! result.get()
			switch message {
			case let .data(data):
				self?.incommingMessagesContinuation.yield(data)
			case let .string(string):
				self?.incommingMessagesContinuation.yield(Data(string.utf8))
			@unknown default:
				fatalError()
			}
			self?.receiveMessages()
		}
	}

	func webSocketTask() -> URLSessionWebSocketTask {
		guard let task else {
			print("Re-Open websocket")
			let newTask = session.webSocketTask(with: url)
			newTask.resume()
			self.task = newTask
			return newTask
		}
		return task
	}

	func cancel() {
		incommingMessagesContinuation.finish()
		task?.cancel(with: .goingAway, reason: nil)
	}
}

// MARK: AsyncWebSocket.Delegate
extension AsyncWebSocket {
	final class Delegate: NSObject, URLSessionWebSocketDelegate, Sendable {
		let onClose: @Sendable () -> Void
		init(onClose: @Sendable @escaping () -> Void = {}) {
			self.onClose = onClose
		}

		func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
			print("Closed websocket")
			onClose()
		}
	}
}

public extension AsyncWebSocket {
	func send(message: Data) async throws {
		try await webSocketTask().send(.data(message))
	}

	private func sendPingContinuously() {
		//                Task {
		//                        task.sendPing { [weak self] _ in
		//                                self?.sendPingContinuously()
		//                        }
		//                }
	}
}
