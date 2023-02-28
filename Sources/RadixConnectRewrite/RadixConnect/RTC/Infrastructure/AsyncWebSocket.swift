import Foundation
import Prelude

// MARK: - AsyncWebSocket
public final class AsyncWebSocket: NSObject, SignalingTransport {
        // MARK: - Private properties

	private let url: URL
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
        private let incommingMessagesContinuation: AsyncStream<Data>.Continuation

        // MARK: - Public API

	public let incommingMessages: AsyncStream<Data>

	public init(url: URL) {
		self.url = url

		(incommingMessages, incommingMessagesContinuation) = AsyncStream.streamWithContinuation()

		super.init()
		receiveMessages()
	}

        public func send(message: Data) async throws {
                try await webSocketTask().send(.data(message))
        }

        public func cancel() {
                incommingMessagesContinuation.finish()
                task?.cancel(with: .goingAway, reason: nil)
        }

        private func sendPingContinuously() {
                Task {
                        try await Task.sleep(for: .seconds(5))
                        try? Task.checkCancellation()
                        guard !Task.isCancelled else {
                                loggerGlobal.debug("Aborting ping, task cancelled.")
                                return
                        }

                        loggerGlobal.trace("Sending ping 🏓")
                        webSocketTask().sendPing { [weak self] error in
                                loggerGlobal.trace("Got pong 🏓")
                                if let error {
                                        loggerGlobal.trace("Failed to send ping: \(String(describing: error))")
                                        self?.cancel()
                                        return
                                }
                                self?.sendPingContinuously()
                        }
                }
        }

        private func receiveMessages() {
                webSocketTask().receive { [weak self] result in
                        guard let message = try? result.get() else {
                                self?.clearTask()
                                self?.receiveMessages()
                                return
                        }
                        switch message {
                        case let .data(data):
                                self?.incommingMessagesContinuation.yield(data)
                        case let .string(string):
                                self?.incommingMessagesContinuation.yield(Data(string.utf8))
                        @unknown default:
                                self?.clearTask()
                                self?.receiveMessages()
                                return
                        }
                        self?.receiveMessages()
                }
        }

        private func clearTask() {
                task?.cancel(with: .goingAway, reason: nil)
                task = nil
        }

        private func webSocketTask() -> URLSessionWebSocketTask {
                guard let task else {
                        let newTask = session.webSocketTask(with: url)
                        newTask.resume()
                        self.task = newTask
                        sendPingContinuously()
                        return newTask
                }
                return task
        }
}

// MARK: AsyncWebSocket.Delegate
extension AsyncWebSocket {
	final class Delegate: NSObject, URLSessionWebSocketDelegate, Sendable {
		let onClose: @Sendable () -> Void
		init(onClose: @Sendable @escaping () -> Void = {}) {
			self.onClose = onClose
		}

                func urlSession(
                        _ session: URLSession,
                        webSocketTask: URLSessionWebSocketTask,
                        didOpenWithProtocol protocol: String?
                ) {
                        loggerGlobal.debug("websocket task=\(webSocketTask.taskIdentifier) didOpenWithProtocol: \(String(describing: `protocol`))")
                }

		func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
                        loggerGlobal.debug("websocket task=\(webSocketTask.taskIdentifier) didCloseWith: \(String(describing: closeCode)), reason: \(String(describing: reason))")
			onClose()
		}
	}
}
