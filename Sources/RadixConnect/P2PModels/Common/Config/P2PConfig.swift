import Foundation

// MARK: - P2PConfig
public struct P2PConfig: Sendable, Hashable, Codable {
	public let connectionPassword: ConnectionPassword
	public let connectorConfig: ConnectorConfig
	public let webRTCConfig: WebRTCConfig
	public let signalingServerConfig: SignalingServerConfig

	public init(
		connectionPassword: ConnectionPassword,
		connectorConfig: ConnectorConfig = .default,
		webRTCConfig: WebRTCConfig = .default,
		signalingServerConfig: SignalingServerConfig = .default
	) {
		self.connectionPassword = connectionPassword
		self.connectorConfig = connectorConfig
		self.webRTCConfig = webRTCConfig
		self.signalingServerConfig = signalingServerConfig
	}
}

extension P2PConfig {
	public var connectionSecrets: ConnectionSecrets {
		try! .from(connectionPassword: connectionPassword)
	}

	public var connectionID: P2PConnectionID {
		connectionSecrets.connectionID
	}
}
