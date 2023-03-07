import CryptoKit
import Foundation
import Prelude
import RadixConnectModels

extension SignalingClient {
	init(password: ConnectionPassword, source: ClientSource = .wallet, baseURL: URL = SignalingClient.prodSignalingServer) throws {
		let connectionURL = try Self.signalingServerURL(connectionPassword: password, source: source, baseURL: baseURL)
		let webSocket = AsyncWebSocket(url: connectionURL)
		let encryptionKey = try EncryptionKey(.init(data: password.data.data))

		self.init(encryptionKey: encryptionKey, transport: webSocket, clientSource: source)
	}
}

/// Connection URL
extension SignalingClient {
	static let prodSignalingServer = URL(string: "wss://signaling-server-betanet.radixdlt.com")!
	static let devSignalingServer = URL(string: "wss://signaling-server-dev.rdx-works-main.extratools.works")!

        #if DEBUG
        static let `default` = SignalingClient.devSignalingServer
        #else
        static let `default` = SignalingClient.prodSignalingServer
        #endif
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
		connectionPassword: ConnectionPassword,
		source: ClientSource,
		baseURL: URL
	) throws -> URL {
		let target: ClientSource = source == .wallet ? .extension : .wallet

		let connectionID = try HexCodable32Bytes(.init(data: connectionPassword.hash))

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
