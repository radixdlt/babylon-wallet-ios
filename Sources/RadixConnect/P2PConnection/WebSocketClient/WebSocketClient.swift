import Combine
import P2PModels
import Prelude

// MARK: - WebSocketClient
public final class WebSocketClient {
	private let url: URL
	private var _webSocketTask: URLSessionWebSocketTask?

	// not owned by this client
	private unowned let stateSubject: CurrentValueSubject<WebSocketState, Never>

	private var delegate: Delegate?

	private final class Delegate: NSObject, URLSessionWebSocketDelegate {
		private let identifier: String
		private var didOpen: () -> Void
		fileprivate var didClose: ((URLSessionWebSocketTask.CloseCode) -> Void)?
		private unowned let stateSubject: CurrentValueSubject<WebSocketState, Never>
		fileprivate init(
			identifier: String,
			stateSubject: CurrentValueSubject<WebSocketState, Never>,
			didOpen: @escaping () -> Void
		) {
			self.stateSubject = stateSubject
			self.identifier = identifier
			self.didOpen = didOpen
		}

		func urlSession(
			_ session: URLSession,
			webSocketTask: URLSessionWebSocketTask,
			didOpenWithProtocol protocol: String?
		) {
			stateSubject.send(.open)
			loggerGlobal.debug("websocket (\(identifier)) task=\(webSocketTask.taskIdentifier) didOpenWithProtocol: \(String(describing: `protocol`))")
			self.didOpen()
		}

		func urlSession(
			_ session: URLSession,
			webSocketTask: URLSessionWebSocketTask,
			didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
			reason: Data?
		) {
			stateSubject.send(.closed(closeCode))
			loggerGlobal.debug("websocket (\(identifier)) task=\(webSocketTask.taskIdentifier) didCloseWith: \(String(describing: closeCode)), reason: \(String(describing: reason))")
			guard let didClose else { return }
			didClose(closeCode)
		}
	}

	public init(url: URL, stateSubject: CurrentValueSubject<WebSocketState, Never>) {
		self.stateSubject = stateSubject
		self.url = url
	}
}

private extension WebSocketClient {
	func webSocketTaskIfRunning() -> URLSessionWebSocketTask? {
		guard let _webSocketTask else { return nil }
		guard _webSocketTask.state == .running || _webSocketTask.state == .suspended else {
			loggerGlobal.warning("WebSocketTask state is not running, it is: \(String(describing: _webSocketTask.state)), so treating it as nil.")
			return nil
		}
		return _webSocketTask
	}
}

public extension WebSocketClient {
	typealias Error = ConverseError.WebSocket

	func connect(didOpen: @escaping @Sendable () -> Void) {
		stateSubject.send(.connecting)
		let webSocketTask = URLSession.shared.webSocketTask(with: url)
		loggerGlobal.debug("Connecting to websocket URL: \(url.absoluteString)")
		defer { webSocketTask.resume() }
		self._webSocketTask = webSocketTask
		let delegate = Delegate(identifier: url.absoluteString, stateSubject: stateSubject, didOpen: didOpen)
		self.delegate = delegate
		webSocketTask.delegate = delegate
	}

	func send(
		data: Data,
		callback: @escaping @Sendable (Result<Void, Error>) -> Void
	) {
		guard let webSocketTask = webSocketTaskIfRunning() else {
			let error = Error.unableToSendDataTaskIsNil
			loggerGlobal.error("Unable to send data over websocket, task is nil")
			callback(.failure(error))
			return
		}
		webSocketTask.send(.data(data)) { maybeError in
			if let error = maybeError {
				loggerGlobal.error("Websocket failed to send message, error: \(String(describing: error))")
				callback(.failure(.sendDataFailed(underlyingError: error)))
			} else {
				callback(.success(()))
			}
		}
	}

	func sendPing(
		callback: @escaping @Sendable (Result<Void, Error>) -> Void
	) {
		guard let webSocketTask = webSocketTaskIfRunning() else {
			let error = Error.unableToPingTaskIsNil
			loggerGlobal.error("Unable to send ping over websocket, task is nil")
			callback(.failure(error))
			return
		}
		webSocketTask.sendPing { maybeError in
			if let error = maybeError {
				loggerGlobal.error("Websocket failed to send ping, error: \(String(describing: error))")
				callback(.failure(.pingFailed(underlyingError: error)))
			} else {
				callback(.success(()))
			}
		}
	}

	func receiveMessage(
		callback: @escaping @Sendable (Result<URLSessionWebSocketTask.Message, Error>) -> Void
	) {
		guard let webSocketTask = webSocketTaskIfRunning() else {
			let error = Error.unableToReceiveTaskIsNil
			loggerGlobal.error("Unable to receive message from websocket, task is nil")
			callback(.failure(error))
			return
		}
		webSocketTask.receive { result in
			switch result {
			case let .success(message):
				loggerGlobal.trace("Received #\(message.byteCount) bytes message over websockets")
				callback(.success(message))
			case let .failure(error):
				loggerGlobal.error("Failed to receive message from websocket, error: \(String(describing: error))")
				callback(.failure(.receiveMessageFailed(underlyingError: error)))
			}
		}
	}

	func close(didClose: @escaping @Sendable (URLSessionWebSocketTask.CloseCode) -> Void) {
		stateSubject.send(.closing)
		loggerGlobal.notice("Closing websocket with url: \(self.url.absoluteString)")
		delegate!.didClose = { [weak self] closeCode in
			self?._webSocketTask = nil
			didClose(closeCode)
		}
		_webSocketTask?.cancel(with: .goingAway, reason: nil)
	}
}

private extension URLSessionWebSocketTask.Message {
	var byteCount: Int {
		switch self {
		case let .data(data): return data.count
		case let .string(string): return string.data(using: .utf8)?.count ?? 0
		@unknown default: return -1
		}
	}
}
