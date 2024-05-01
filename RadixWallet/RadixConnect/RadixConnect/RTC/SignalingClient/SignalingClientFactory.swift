import Sargon
import WebRTC

extension SignalingClient {
	init(
		password: RadixConnectPassword,
		source: ClientSource = .wallet,
		baseURL: URL
	) throws {
		let connectionURL = try Self.signalingServerURL(connectionPassword: password, source: source, baseURL: baseURL)
		let webSocket = AsyncWebSocket(url: connectionURL)
		let encryptionKey = EncryptionKey(password.value)

		self.init(encryptionKey: encryptionKey, transport: webSocket, clientSource: source)
	}
}

/// Connection URL
extension SignalingClient {
	static let `default` = RadixConnectConstants.defaultSignalingServer
}

/// Signaling Server URL build
extension SignalingClient {
	struct FailedToCreateSignalingServerURL: LocalizedError {
		var errorDescription: String? {
			"Failed to create url"
		}
	}

	enum QueryParameterName: String {
		case target, source
	}

	static func signalingServerURL(
		connectionPassword: RadixConnectPassword,
		source: ClientSource,
		baseURL: URL
	) throws -> URL {
		let target: ClientSource = source == .wallet ? .extension : .wallet

		let connectionID = connectionPassword.hash().bytes

		let url = baseURL.appendingPathComponent(
			connectionID.data.hex()
		)

		guard
			var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
		else {
			throw FailedToCreateSignalingServerURL()
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
			throw FailedToCreateSignalingServerURL()
		}

		return serverURL
	}
}
