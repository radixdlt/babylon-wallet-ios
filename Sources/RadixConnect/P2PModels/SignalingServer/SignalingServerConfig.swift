import Foundation

// MARK: - SignalingServerConfig
public struct SignalingServerConfig: Sendable, Hashable, Codable {
	private let signalingServerBaseURL: URL
	public let websocketPingInterval: TimeInterval?

	public init(
		websocketPingInterval: TimeInterval? = 55,
		signalingServerBaseURL: URL = .defaultBaseForSignalingServer
	) {
		self.signalingServerBaseURL = signalingServerBaseURL
		self.websocketPingInterval = websocketPingInterval
	}

	public static let `default` = Self()
}

extension URL {
	public static let defaultBaseForSignalingServer = Self(string: "wss://signaling-server-betanet.radixdlt.com")!
}

extension SignalingServerConfig {
	public func signalingServerURL(
		connectionID: P2PConnectionID,
		source: ClientSource = .mobileWallet
	) throws -> URL {
		let target: ClientSource = source == .mobileWallet ? .browserExtension : .mobileWallet

		let url = signalingServerBaseURL.appendingPathComponent(
			connectionID.hex()
		)

		guard
			var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
		else {
			throw ConverseError.signalingServer(.failedToCreateSignalingServerURLInvalidPath)
		}

		urlComponents.queryItems = [
			.init(
				name: QueryParameterName.target.rawValue,
				value: target.rawValue
			),
			.init(
				name: QueryParameterName.source.rawValue,
				value: source.rawValue
			),
		]

		guard let serverURL = urlComponents.url else {
			throw ConverseError.signalingServer(.failedToCreateSignalingServerURLInvalidQueryParameters)
		}

		return serverURL
	}
}

// MARK: - SignalingServerConfig.QueryParameterName
extension SignalingServerConfig {
	fileprivate enum QueryParameterName: String {
		case target, source
	}
}

#if DEBUG
extension SignalingServerConfig {
	public static let placeholder = Self.default
}
#endif // DEBUG
