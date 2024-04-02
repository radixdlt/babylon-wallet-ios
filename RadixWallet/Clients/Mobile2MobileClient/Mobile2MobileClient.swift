import CryptoKit
import Foundation

// MARK: - Mobile2MobileClient
struct Mobile2MobileClient: DependencyKey {
	var handleRequest: HandleRequest
}

extension Mobile2MobileClient {
	struct WalletConnectRequest: Sendable {
		let dAppOrigin: URL
		let publicKey: Curve25519.KeyAgreement.PublicKey
		let sessionId: UUID
	}

	typealias HandleRequest = (WalletConnectRequest) async throws -> Void
}

extension Mobile2MobileClient {
	enum Error: Swift.Error {
		case missingDappReturnURL
	}

	static var liveValue: Mobile2MobileClient {
		@Dependency(\.httpClient) var httpClient
		@Dependency(\.openURL) var openURL
		@Dependency(\.overlayWindowClient) var overlayWindowClient

		func getDappReturnURL(_ dAppOrigin: URL, sessionId: UUID) async throws -> String {
			let wellKnown = try await httpClient.fetchDappWellKnownFile(dAppOrigin)
			guard let returnURL = wellKnown.callbackPath else {
				throw Error.missingDappReturnURL
			}
			return dAppOrigin.absoluteString + "/" + returnURL // dAppOrigin.appending(component: returnURL)
		}

		return .init(
			handleRequest: { request in
				let dappReturnURL = try await getDappReturnURL(request.dAppOrigin, sessionId: request.sessionId)

				loggerGlobal.critical("Creating the Wallet Private/Public key pair")

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

				let returnURL = dappReturnURL + "?publicKey=\(walletPublicKey.rawRepresentation.hex)&sessionId=\(request.sessionId.uuidString)&secret=\(sharedSecret.hex)"
				//                let returnURL = dappReturnURL.appending(queryItems: [
				//                    .init(name: "publicKey", value: walletPublicKey.rawRepresentation.hex),
				//                    .init(name: "sessionId", value: request.sessionId.uuidString),
				//                    .init(name: "secret", value: sharedSecret.hex)
				//                ])

				await openURL(.init(string: returnURL)!)
			})
	}
}

extension DependencyValues {
	var mobile2MobileClient: Mobile2MobileClient {
		get { self[Mobile2MobileClient.self] }
		set { self[Mobile2MobileClient.self] = newValue }
	}
}
