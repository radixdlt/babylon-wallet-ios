import Foundation
import Network
import Prelude

// MARK: - DispatchQueue.SchedulerOptions + Sendable
extension DispatchQueue.SchedulerOptions: @unchecked Sendable {}

// MARK: - DispatchQueue.SchedulerTimeType.Stride + Sendable
extension DispatchQueue.SchedulerTimeType.Stride: @unchecked Sendable {}

// MARK: - AsyncWebSocket
/*
 A WebSocket implementation with AsyncAPI.
 One of the main functionality of this component is the recovering after
 any possible error: send/receive errors, aswell intternet connection going down.
 This is very crucial, failing to reconnect the websocket will result in inability to establish new peer connections.
 */
public final actor AsyncWebSocket: NSObject, SignalingTransport {
	struct UnknownMessageTypeError: Error {}
	struct NoSessionAvailableError: Error {}

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

	let monitor = NWPathMonitor()
	private let url: URL
	private let sessionConfig: URLSessionConfiguration
	private var session: WebSocketSession?
	private let clock: any Clock<Duration>

	// MARK: - State
	private let IncomingMessagesContinuation: AsyncStream<Data>.Continuation
	private var isRestarting: Bool = false
	private var isConnectedToInternet: Bool = false
	private var pingTask: Task<Void, Error>? = nil
	private var receiveMessagesTask: Task<Void, Error>? = nil
	private var terminated: Bool = false

	// MARK: - Internal API
	let incomingMessages: AsyncStream<Data>

	init(
		url: URL,
		sessionConfig: URLSessionConfiguration = .default,
		clock: any Clock<Duration> = ContinuousClock()
	) {
		self.url = url
		self.sessionConfig = sessionConfig
		// Will wait for the internet connection to be re-established in case of a disconnect
		self.sessionConfig.waitsForConnectivity = true
		self.clock = clock

		(incomingMessages, IncomingMessagesContinuation) = AsyncStream.streamWithContinuation()

		super.init()

		monitor.pathUpdateHandler = { [weak self] path in
			guard let self else { return }
			switch path.status {
			case .unsatisfied:
				Task {
					await self.handleNoInternetConnection()
				}
			case .satisfied:
				Task {
					await self.handleInternetConnectionEstablished()
				}
			default:
				break
			}
		}

		let queue = DispatchQueue(label: "Monitor")
		monitor.start(queue: queue)
	}
}

extension AsyncWebSocket {
	func send(message: Data) async throws {
		guard let session else {
			loggerGlobal.info("WebSocket: Attempt to send message when session was invalidated")
			await invalidateAndRestartSession()
			// We could attemtpt to send the message after connection was established,
			// but most probably the other client will not expect to receive it, since
			// it will receive `remoteClientDidDisconnect` from the SS.
			throw NoSessionAvailableError()
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
		terminated = true
		IncomingMessagesContinuation.finish()
		pingTask?.cancel()
		invalidateSession()
		monitor.cancel()
		receiveMessagesTask?.cancel()
	}
}

extension AsyncWebSocket {
	private func receiveMessages() {
		receiveMessagesTask = Task {
			try? Task.checkCancellation()
			guard !Task.isCancelled else {
				loggerGlobal.debug("WebSocket: Aborting receive messages, task cancelled.")
				return
			}

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
						self.IncomingMessagesContinuation.yield(data)
					case let .string(string):
						self.IncomingMessagesContinuation.yield(Data(string.utf8))
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
	}

	private func sendPingContinuously() {
		pingTask = Task {
			try? await clock.sleep(for: .seconds(Config.default.pingInterval))
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

extension AsyncWebSocket {
	private func handleNoInternetConnection() {
		// Handle only if previous state was connected
		guard isConnectedToInternet else { return }

		invalidateSession()
		isConnectedToInternet = false
	}

	private func handleInternetConnectionEstablished() {
		// Handle only if previous state was disconnected
		guard !isConnectedToInternet else { return }

		startSession()
		isConnectedToInternet = true
	}

	private func invalidateSession() {
		guard !terminated else { return }

		guard let session else {
			loggerGlobal.info("WebSocket: Attempt to invalidate a missing session")
			return
		}
		session.task.cancel(with: .normalClosure, reason: nil)
		session.urlSession.invalidateAndCancel()
		self.session = nil
		loggerGlobal.info("WebSocket: Session was invalidated and terminated")
	}

	private func invalidateAndRestartSession() async {
		guard !isRestarting else { return }

		isRestarting = true
		loggerGlobal.info("WebSocket: Invalidate session and restart")
		invalidateSession()

		try? await clock.sleep(for: .seconds(Config.default.reconnectDelay))
		startSession()
		isRestarting = false
	}

	private func startSession() {
		guard !terminated else { return }
		guard session == nil else {
			loggerGlobal.info("Tried to start a session when existing one is still valid")
			return
		}

		let delegate = Delegate(onClose: { [weak self] in
			guard let self else { return }
			Task {
				await self.invalidateAndRestartSession()
			}
		}, onOpen: { [weak self] in
			guard let self else { return }
			Task {
				await self.receiveMessages()
				await self.sendPingContinuously()
				loggerGlobal.info("WebSocket: Session Started")
			}
		})

		let urlSession = URLSession(configuration: sessionConfig, delegate: delegate, delegateQueue: nil)
		let task = urlSession.webSocketTask(with: url)
		task.resume()
		self.session = .init(urlSession: urlSession, task: task)
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
