import Prelude

// MARK: - P2PClient
/// A client the user have connected P2P with, typically a
/// WebRTC connections with a DApp, but might be Android or iPhone
/// client as well.
public struct P2PClient:
	Sendable,
	Hashable,
	Codable,
	Identifiable,
	CustomStringConvertible
{
	/// The most important property of this struct, the `ConnectionPassword`,
	/// is used to be able to restablish the P2P connection and also acts as the seed
	/// for the `ID`.
	public let connectionPassword: ConnectionPassword

	/// A custom `WebRTCConfig` which will be used instead of the `default` one.
	public let webRTCConfig: WebRTCConfig?

	/// A custom `SignalingServerConfig` which will be used instead of the `default` one.
	public let signalingServerConfig: SignalingServerConfig?

	/// A custom `ConnectorConfig` which will be used instead of the `default` one.
	public let connectorConfig: ConnectorConfig?

	/// The platform of the remote client, either `Browser`, or `Android` or `iPhone`.
	public let platform: Platform

	/// Client name, e.g. "Chrome on Macbook" or "My work Android" or "My wifes iPhone SE".
	public let displayName: String

	public let firstEstablishedOn: Date
	public let lastUsedOn: Date

	/// The canonical initializer requiring a `ConnectionPassword` and `Display` name.
	public init(
		connectionPassword: ConnectionPassword,
		customWebRTCConfig: WebRTCConfig? = nil,
		customSignalingServerConfig: SignalingServerConfig? = nil,
		customConnectorConfig: ConnectorConfig? = nil,
		displayName: String,
		platform: Platform = .browser,
		firstEstablishedOn: Date = .init(),
		lastUsedOn: Date = .init()
	) {
		self.connectionPassword = connectionPassword
		self.webRTCConfig = customWebRTCConfig
		self.signalingServerConfig = customSignalingServerConfig
		self.connectorConfig = customConnectorConfig
		self.platform = platform
		self.displayName = displayName
		self.firstEstablishedOn = firstEstablishedOn.stableEquatableAfterJSONRoundtrip
		self.lastUsedOn = lastUsedOn.stableEquatableAfterJSONRoundtrip
	}
}

extension P2PClient {
	/// Convenience init if you want to specfity a `P2PConfig` in full. Which will use the
	/// `config.webRTCConfig` as customWebRTCConfig overriding the default one when decoded and
	/// analogously for `config.signalingServerConfig`.
	public init(
		config: P2PConfig,
		displayName: String,
		platform: Platform = .browser,
		firstEstablishedOn: Date = .init(),
		lastUsedOn: Date = .init()
	) {
		self.init(
			connectionPassword: config.connectionPassword,
			customWebRTCConfig: config.webRTCConfig,
			customSignalingServerConfig: config.signalingServerConfig,
			customConnectorConfig: config.connectorConfig,
			displayName: displayName,
			platform: platform,
			firstEstablishedOn: firstEstablishedOn,
			lastUsedOn: lastUsedOn
		)
	}

	/// P2PConfig using the stored `connectionPassword` and custom `webRTCConfig` if any, else the
	/// `WebRTCConfig.default` will be used and analogously for `signalingServerConfig`, using the custom
	/// one if present, else `SignalingServerConfig.default` will be used, and analogously for `connectorConfig`
	public var config: P2PConfig {
		.init(
			connectionPassword: connectionPassword,
			connectorConfig: self.connectorConfig ?? .default,
			webRTCConfig: self.webRTCConfig ?? .default,
			signalingServerConfig: self.signalingServerConfig ?? .default
		)
	}
}

// MARK: P2PClient.Platform
extension P2PClient {
	/// The platform of the remote client, either `Browser`, or `Android` or `iPhone`.
	public enum Platform:
		String,
		Sendable,
		Hashable,
		Codable,
		CustomStringConvertible
	{
		case browser
		case android
		case iPhone
	}
}

extension P2PClient {
	public typealias ID = P2PConnectionID
	public var id: P2PConnectionID {
		config.connectionID
	}

	public static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.connectionPassword == rhs.connectionPassword
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(connectionPassword)
	}
}

extension P2PClient {
	public var description: String {
		"""
		connectionPasswordMasked: \(connectionPassword.hexMask(showLast: 6)),
		platform: \(platform),
		displayName: \(displayName),
		firstEstablishedOn: \(firstEstablishedOn.ISO8601Format()),
		lastUsedOn: \(lastUsedOn.ISO8601Format()),
		connectorConfig: \(String(describing: connectorConfig)),
		webRTCConfig: \(String(describing: webRTCConfig)),
		signalingServerConfig: \(String(describing: signalingServerConfig)),
		"""
	}
}

extension String {
	public func mask(showLast suffixCount: Int) -> String.SubSequence {
		"..." + suffix(suffixCount)
	}
}

extension Data {
	public func hexMask(showLast suffixCount: Int) -> String.SubSequence {
		hex().mask(showLast: suffixCount)
	}
}

extension HexCodable {
	public func hexMask(showLast suffixCount: Int) -> String.SubSequence {
		data.hexMask(showLast: suffixCount)
	}
}

extension ConnectionPassword {
	public func hexMask(showLast suffixCount: Int) -> String.SubSequence {
		data.hexMask(showLast: suffixCount)
	}
}

// MARK: - Date + Sendable
extension Date: @unchecked Sendable {}

// MARK: - Data + Sendable
extension Data: @unchecked Sendable {}

extension Date {
	/// Ugly hack around the fact that dates differs when encoded and decoded, by some nanoseconds or something... urgh!
	public var stableEquatableAfterJSONRoundtrip: Self {
		let jsonEncoder = JSONEncoder()
		jsonEncoder.dateEncodingStrategy = .iso8601
		let jsonDecoder = JSONDecoder()
		jsonDecoder.dateDecodingStrategy = .iso8601
		let data = try! jsonEncoder.encode(self)
		let persistable = try! jsonDecoder.decode(Self.self, from: data)
		return persistable
	}
}

// MARK: - P2PClient.Platform + CustomDumpRepresentable
extension P2PClient.Platform: CustomDumpRepresentable {
	public var customDumpValue: Any {
		rawValue
	}
}

// MARK: - P2PClient + CustomDumpReflectable
extension P2PClient: CustomDumpReflectable {
	public var customDumpMirror: Mirror {
		.init(
			self,
			children: [
				"connectionPasswordMasked": connectionPassword.hexMask(showLast: 6),
				"platform": platform,
				"displayName": displayName,
				"firstEstablishedOn": firstEstablishedOn.ISO8601Format(),
				"lastUsedOn": lastUsedOn.ISO8601Format(),
				"connectorConfig": connectorConfig.map { String(describing: $0) } ?? "nil",
				"webRTCConfig": webRTCConfig.map { String(describing: $0) } ?? "nil",
				"signalingServerConfig": signalingServerConfig.map { String(describing: $0) } ?? "nil",
			],
			displayStyle: .struct
		)
	}
}
