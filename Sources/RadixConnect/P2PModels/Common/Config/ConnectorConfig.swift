import Prelude

// MARK: - OrderedSet + Sendable
extension OrderedSet: @unchecked Sendable where Element: Sendable {}

// MARK: - ConnectorConfig
public struct ConnectorConfig: Sendable, Hashable, Codable {
	public let reconnectRetryDelay: TimeInterval
	public let establishConnectionTimeout: TimeInterval
	public let retryAttempts: Int
	public let connectionStatusesTriggeringReconnect: OrderedSet<ConnectionStatus>

	public init(
		reconnectRetryDelay: TimeInterval = 1,
		establishConnectionTimeout: TimeInterval = 10,
		retryAttempts: Int = 3,
		connectionStatusesTriggeringReconnect: OrderedSet<ConnectionStatus> = .init([.failed, .closed])
	) {
		self.reconnectRetryDelay = reconnectRetryDelay
		self.establishConnectionTimeout = establishConnectionTimeout
		self.retryAttempts = retryAttempts
		self.connectionStatusesTriggeringReconnect = connectionStatusesTriggeringReconnect
	}

	public static let `default` = Self()
}
