import CryptoKit
import Foundation

// MARK: - Mobile2MobileClient
public struct Mobile2MobileClient: DependencyKey {
	public var handleRequest: HandleRequest
}

extension Mobile2MobileClient {
	public struct WalletConnectRequest: Sendable {
		public let dAppOrigin: URL
		public let publicKeyHex: String
		public let sessionId: String
	}

	public typealias HandleRequest = (WalletConnectRequest) async throws -> Void
}

extension Mobile2MobileClient {
	public struct SessionConnection: Codable, Sendable {
		public struct ID: Codable, Sendable {
			public var id: String {
				dAppOrigin + sessionId
			}

			public let dAppOrigin: String
			public let sessionId: String
		}

		public let id: ID
		public let walletPrivateKey: HexCodable32Bytes
		public let dAppPublicKey: HexCodable32Bytes
	}

	public enum Error: Swift.Error {
		case missingDappReturnURL
	}

	public static var liveValue: Mobile2MobileClient {
		@Dependency(\.httpClient) var httpClient
		@Dependency(\.openURL) var openURL
		@Dependency(\.overlayWindowClient) var overlayWindowClient
		@Dependency(\.secureStorageClient) var secureStorageClient

		func getDappReturnURL(_ dAppOrigin: URL) async throws -> URL {
			let wellKnown = try await httpClient.fetchDappWellKnownFile(dAppOrigin)
			guard let returnURL = wellKnown.callbackPath else {
				throw Error.missingDappReturnURL
			}
			return .init(string: dAppOrigin.absoluteString + returnURL)! // dAppOrigin.appending(component: returnURL)
		}

		return .init(
			handleRequest: { request in
				let dappReturnURL = try await getDappReturnURL(request.dAppOrigin)

				loggerGlobal.critical("Creating the Wallet Private/Public key pair")

				let walletPrivateKey = Curve25519.KeyAgreement.PrivateKey()
				let walletPublicKey = walletPrivateKey.publicKey

				let returnURL = dappReturnURL.appending(queryItems: [
					.init(name: "publicKey", value: walletPublicKey.rawRepresentation.hex),
					.init(name: "sessionId", value: request.sessionId),
				])

				try secureStorageClient.saveMobile2MobileSessionSecret(
					.init(
						id: .init(dAppOrigin: request.dAppOrigin.absoluteString, sessionId: request.sessionId),
						walletPrivateKey: .init(hex: walletPrivateKey.rawRepresentation.hex),
						dAppPublicKey: .init(hex: request.publicKeyHex)
					)
				)

				await openURL(returnURL)
			})
	}
}

extension DependencyValues {
	public var mobile2MobileClient: Mobile2MobileClient {
		get { self[Mobile2MobileClient.self] }
		set { self[Mobile2MobileClient.self] = newValue }
	}
}
