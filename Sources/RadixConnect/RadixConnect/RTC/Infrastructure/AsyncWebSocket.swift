import Foundation
import Prelude

// MARK: - DispatchQueue.SchedulerOptions + Sendable
extension DispatchQueue.SchedulerOptions: @unchecked Sendable {}

// MARK: - DispatchQueue.SchedulerTimeType.Stride + Sendable
extension DispatchQueue.SchedulerTimeType.Stride: @unchecked Sendable {}

// MARK: - AsyncWebSocket
public final actor AsyncWebSocket: NSObject, SignalingTransport {
	struct UnknownMessageTypeError: Error {}


	// MARK: - Configuration
        struct WebSocketSession {
                let urlSession: URLSession
                let task: URLSessionWebSocketTask
        }

        struct Config {
                let reconnectDelay: Double
                let pingInterval: Double

                static let `default` = Config(reconnectDelay: 5, pingInterval: 60)
        }

	private let url: URL
	private let sessionConfig: URLSessionConfiguration
        private var session: WebSocketSession?
	private let scheduler: AnySchedulerOf<DispatchQueue>

        // MARK: - State
	private let incommingMessagesContinuation: AsyncStream<Data>.Continuation
	private var isRestarting: Bool = false

	// MARK: - Internal API
        let incommingMessages: AsyncStream<Data>

        init(url: URL, sessionConfig: URLSessionConfiguration = .default, scheduler: AnySchedulerOf<DispatchQueue> = DispatchQueue.global().eraseToAnyScheduler()) {
		self.url = url
		self.sessionConfig = sessionConfig
		self.sessionConfig.waitsForConnectivity = true
		self.scheduler = scheduler

		(incommingMessages, incommingMessagesContinuation) = AsyncStream.streamWithContinuation()

		super.init()
		Task { await self.startSession() }
	}

        func send(message: Data) async throws {
                guard let session else {
                        loggerGlobal.info("WebSocket: Attempt to send message when session was invalidated")
                        await invalidateAndRestartSession()
                        try await send(message: message)
                        return
                }
                do {
                        try await session.task.send(.data(message))
                } catch {
                        Task {
                                await invalidateAndRestartSession()
                        }
                        throw error
                }
        }

        func cancel() async {
                incommingMessagesContinuation.finish()
                invalidateSession()
        }

        // MARK: - Private API

	private func invalidateSession() {
		guard let session else {
			loggerGlobal.info("WebSocket: Attempt to invalidate a missing session")
			return
		}
		session.task.cancel(with: .normalClosure, reason: nil)
		session.urlSession.invalidateAndCancel()
		loggerGlobal.info("WebSocket: Session was invalidated and terminated")
	}

	private func invalidateAndRestartSession() async {
		guard !isRestarting else { return }

		isRestarting = true
		loggerGlobal.info("WebSocket: Invalidate session and restart")
		invalidateSession()

                try? await scheduler.sleep(for: .seconds(Config.default.reconnectDelay))
		startSession()
		isRestarting = false
	}

	private func startSession() {
		let delegate = Delegate(onClose: {
			Task {
				await self.invalidateAndRestartSession()
			}
		}, onOpen: {
			Task {
				await self.receiveMessages()
				await self.sendPingContinuously()
				loggerGlobal.info("WebSocket: Session Restarted")
			}
		})

		let urlSession = URLSession(configuration: sessionConfig, delegate: delegate, delegateQueue: nil)
		let task = urlSession.webSocketTask(with: url)
                task.resume()
		self.session = .init(urlSession: urlSession, task: task)
	}

        private func receiveMessages() {
                guard let session else {
                        loggerGlobal.info("WebSocket: Session was invalidated, stop receiving messages")
                        return
                }

                session.task.receive { [weak self] result in
                        guard let self else { return }
                        do {
                                let message = try result.get()
                                switch message {
                                case let .data(data):
                                        self.incommingMessagesContinuation.yield(data)
                                case let .string(string):
                                        self.incommingMessagesContinuation.yield(Data(string.utf8))
                                @unknown default:
                                        throw UnknownMessageTypeError()
                                }
                        } catch {
                                loggerGlobal.error("WebSocket: receive message failed \(error)")
                                return
                        }

                        Task {
                                await self.receiveMessages()
                        }
                }
        }

	private func sendPingContinuously() {
		Task {
                        try? await scheduler.sleep(for: .seconds(Config.default.pingInterval))
			try? Task.checkCancellation()
			guard !Task.isCancelled else {
				loggerGlobal.debug("WebSocket: Aborting ping, task cancelled.")
				return
			}

			guard let session else {
				loggerGlobal.info("WebSocket: Attempt to send Ping when session was invalidated")
				return
			}

			loggerGlobal.trace("WebSocket:Sending ping 🏓")
			session.task.sendPing { [weak self] error in
				guard let self else { return }
				if let error {
					loggerGlobal.trace("WebSocket: Failed to send ping: \(String(describing: error))")
					return
				}
				loggerGlobal.trace("WebSocket: Got pong 🏓")
				Task {
					await self.sendPingContinuously()
				}
			}
		}
	}
}

// MARK: AsyncWebSocket.Delegate
extension AsyncWebSocket {
	final class Delegate: NSObject, URLSessionWebSocketDelegate, Sendable {
		let onClose: @Sendable () -> Void
		let onOpen: @Sendable () -> Void

		init(onClose: @Sendable @escaping () -> Void = {}, onOpen: @Sendable @escaping () -> Void = {}) {
			self.onClose = onClose
			self.onOpen = onOpen
		}

                // MARK: - Open events

		func urlSession(
			_ session: URLSession,
			webSocketTask: URLSessionWebSocketTask,
			didOpenWithProtocol protocol: String?
		) {
			loggerGlobal.debug("websocket task=\(webSocketTask.taskIdentifier) didOpenWithProtocol: \(String(describing: `protocol`))")
			onOpen()
		}

                // MARK: - Close events

		func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
			loggerGlobal.debug("websocket task=\(webSocketTask.taskIdentifier) didCloseWith: \(String(describing: closeCode)), reason: \(String(describing: reason))")
			onClose()
		}

		func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
			loggerGlobal.debug("WebSocket session didBecomeInvalid, reason: \(String(describing: error))")
			onClose()
		}

		func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
                        loggerGlobal.debug("WebSocket: Task failed with error \(String(describing: error))")
			onClose()
		}

                // MARK: - Connectivity

                func urlSession(_ session: URLSession, taskIsWaitingForConnectivity task: URLSessionTask) {
                        loggerGlobal.debug("WebSocket: Internet connection seems to be down, waiting for connectivity")
                }
	}
}
