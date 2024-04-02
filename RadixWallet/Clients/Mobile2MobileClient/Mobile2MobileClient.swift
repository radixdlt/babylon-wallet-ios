import CryptoKit
import Foundation

// MARK: - Mobile2MobileClient
public struct Mobile2MobileClient: DependencyKey {
	public var handleRequest: HandleRequest
}

extension Mobile2MobileClient {
	public struct WalletConnectRequest: Sendable {
		public let dAppOrigin: URL
		public let publicKey: Curve25519.KeyAgreement.PublicKey
		public let sessionId: String
	}

	public typealias HandleRequest = (WalletConnectRequest) async throws -> Void
}

extension Mobile2MobileClient {
	public struct SessionConnectionID: Codable {
		public var id: String {
			dAppOrigin + sessionId
		}

		public let dAppOrigin: String
		public let sessionId: String
	}

	public enum Error: Swift.Error {
		case missingDappReturnURL
	}

	public static var liveValue: Mobile2MobileClient {
		@Dependency(\.httpClient) var httpClient
		@Dependency(\.openURL) var openURL
		@Dependency(\.overlayWindowClient) var overlayWindowClient

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

				// Generate Private/Public key pair.
				// Store the private key in Keychain

				let walletPrivateKey = Curve25519.KeyAgreement.PrivateKey()
				let walletPublicKey = walletPrivateKey.publicKey
				loggerGlobal.critical("Wallet Public key created \(walletPublicKey.rawRepresentation.hex)")
				loggerGlobal.critical("Generating shared secret...")

				let sharedSecret = try walletPrivateKey.sharedSecretFromKeyAgreement(with: request.publicKey)
				loggerGlobal.critical("Genereted shared secret \(sharedSecret.hex)")
				loggerGlobal.critical("Returning to the dApp with the wallet public key")

				_ = await overlayWindowClient.scheduleAlertAwaitAction(.init(title: {
						.init("Genereted shared secret")
					}, actions: {
						ButtonState(
							role: .none,
							action: .primaryButtonTapped,
							label: {
								.init("Continue to dApp")
							}
						)
					},
					message: {
						.init(sharedSecret.hex)
					}))

				let returnURL = dappReturnURL.appending(queryItems: [
					.init(name: "publicKey", value: walletPublicKey.rawRepresentation.hex),
					.init(name: "sessionId", value: request.sessionId),
				])

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
