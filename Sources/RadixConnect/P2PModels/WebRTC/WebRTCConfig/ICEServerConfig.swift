import Foundation

// MARK: - ICEServerConfig
public struct ICEServerConfig: Sendable, Hashable, Codable, CustomStringConvertible {
	public let url: URL
	public let credentials: Credentials?

	public init(
		url: URL,
		credentials: Credentials? = nil
	) {
		self.url = url
		self.credentials = credentials
	}

	public init?(url urlString: String) {
		guard let url = URL(string: urlString) else {
			return nil
		}
		self.init(url: url)
	}
}

public extension ICEServerConfig {
	var description: String {
		"""
		url: \(url),
		credentials: \(String(describing: credentials))
		"""
	}
}

// MARK: ICEServerConfig.Credentials
public extension ICEServerConfig {
	struct Credentials: Sendable, Hashable, Codable, CustomStringConvertible {
		public let username: String
		public let password: String
		public init(username: String, password: String) {
			self.username = username
			self.password = password
		}
	}
}

public extension ICEServerConfig.Credentials {
	var description: String {
		"""
		username: \(username),
		password: \(password)
		"""
	}
}

public extension Array where Element == ICEServerConfig {
	// TURN and possibly STUN servers.
	//
	// Other potential stun servers are:
	// "stun.services.mozilla.org",
	// "stun:stun.stunprotocol.org",
	static let `default`: Self = [
		ICEServerConfig?.none,
		.init(
			url: .init(string: "turn:turn-betanet-udp.radixdlt.com:80?transport=udp")!,
			credentials: .unsafe
		),
		.init(
			url: .init(string: "turn:turn-betanet-tcp.radixdlt.com:80?transport=tcp")!,
			credentials: .unsafe
		),
		ICEServerConfig(url: "stun:stun.l.google.com:19302"),
		ICEServerConfig(url: "stun:stun1.l.google.com:19302"),
		ICEServerConfig(url: "stun:stun2.l.google.com:19302"),
		ICEServerConfig(url: "stun:stun3.l.google.com:19302"),
		ICEServerConfig(url: "stun:stun4.l.google.com:19302"),
	].compactMap { $0 }
}

public extension ICEServerConfig.Credentials {
	static let unsafe = Self(username: "username", password: "password")
}

#if DEBUG
extension ICEServerConfig: ExpressibleByStringLiteral {
	public init(stringLiteral value: StringLiteralType) {
		self.init(url: .init(string: value)!)
	}
}

public extension URL {
	static let placeholder = Self(string: "stun:stun.l.google.com:19302")!
}

public extension ICEServerConfig {
	static let placeholder = Self(url: .placeholder)
}
#endif // DEBUG
