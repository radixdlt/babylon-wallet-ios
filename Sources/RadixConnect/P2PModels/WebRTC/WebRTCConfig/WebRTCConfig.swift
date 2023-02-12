import Foundation

// MARK: - WebRTCConfig
public struct WebRTCConfig: Sendable, Hashable, Codable, CustomStringConvertible {
	public let peerConnectionConfig: WebRTCPeerConnectionConfig
	public let dataChannelConfig: WebRTCDataChannelConfig

	public init(
		peerConnectionConfig: WebRTCPeerConnectionConfig = .default,
		dataChannelConfig: WebRTCDataChannelConfig = .default
	) {
		self.peerConnectionConfig = peerConnectionConfig
		self.dataChannelConfig = dataChannelConfig
	}

	public static let `default` = Self()
}

extension WebRTCConfig {
	public var description: String {
		"""
		peerConnectionConfig: \(peerConnectionConfig),
		dataChannelConfig: \(dataChannelConfig)
		"""
	}
}

#if DEBUG
extension WebRTCConfig {
	public static let placeholder = Self(
		peerConnectionConfig: .placeholder,
		dataChannelConfig: .placeholder
	)
}
#endif // DEBUG
