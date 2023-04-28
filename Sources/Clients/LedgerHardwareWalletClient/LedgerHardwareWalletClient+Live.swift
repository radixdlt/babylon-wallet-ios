import AccountsClient
import ClientPrelude
import ComposableArchitecture // actually CasePaths... but CI fails if we do `import CasePaths` 🤷‍♂️
import Cryptography
import RadixConnectClient

// MARK: - LedgerHardwareWalletClient + DependencyKey
extension LedgerHardwareWalletClient: DependencyKey {
	public typealias Value = LedgerHardwareWalletClient

	public static let liveValue: Self = {
		@Dependency(\.radixConnectClient) var radixConnectClient

		@Sendable func makeRequest<Response: Sendable>(
			_ request: P2P.ConnectorExtension.Request.LedgerHardwareWallet.Request,
			responseCasePath: CasePath<P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success, Response>
		) async throws -> Response {
			let interactionID = P2P.LedgerHardwareWallet.InteractionId.random()

			loggerGlobal.debug("About to broadcast importOlympiaDevice request with interactionID: \(interactionID)..")

			var clientsLeftToReceiveAnswerFrom = try await radixConnectClient
				.sendRequest(.connectorExtension(.ledgerHardwareWallet(.init(interactionID: interactionID, request: request))), .broadcastToAllPeers)

			loggerGlobal.debug("Broadcasted importOlympiaDevice request with interactionID: \(interactionID) ✅ waiting for response")

			for try await incomingResponse in await radixConnectClient.receiveResponses(/P2P.RTCMessageFromPeer.Response.connectorExtension .. /P2P.ConnectorExtension.Response.ledgerHardwareWallet) {
				loggerGlobal.notice("Received response from CE: \(String(describing: incomingResponse))")
				guard !Task.isCancelled else {
					throw CancellationError()
				}
				guard clientsLeftToReceiveAnswerFrom >= 0 else {
					break
				}

				let response = try incomingResponse.result.get()

				guard response.interactionID == interactionID else {
					continue // irrelevant response, do not decrease `clientsLeftToReceiveAnswerFrom`
				}

				switch response.response {
				case let .success(successValue):
					if let responseValue = responseCasePath.extract(from: successValue) {
						return responseValue
					} else {
						break
					}
				case let .failure(errorFromConnectorExtension):
					loggerGlobal.warning("Error from CE? \(errorFromConnectorExtension)")
				}

				clientsLeftToReceiveAnswerFrom -= 1
			}

			throw FailedToReceiveAnyResponseFromAnyClient()
		}

		return Self(
			isConnectedToAnyConnectorExtension: {
				await radixConnectClient.getP2PLinksWithConnectionStatusUpdates()
					.map { !$0.filter(\.hasAnyConnectedPeers).isEmpty }
					.share()
					.eraseToAnyAsyncSequence()
			},
			getDeviceInfo: {
				try await makeRequest(
					.getDeviceInfo,
					responseCasePath: /P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.getDeviceInfo
				)
			},
			importOlympiaDevice: { olympiaHardwareAccounts in

				try await makeRequest(
					.importOlympiaDevice(.init(derivationPaths: olympiaHardwareAccounts.map(\.path.derivationPath))),
					responseCasePath: /P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.importOlympiaDevice
				)
			},
			deriveCurve25519PublicKey: { derivationPath, factorSource in
				let response = try await makeRequest(
					.derivePublicKey(.init(
						keyParameters: .init(
							curve: .curve25519,
							derivationPath: derivationPath.path
						),
						ledgerDevice: .init(from: factorSource)
					)),
					responseCasePath: /P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.derivePublicKey
				)

				return try .init(compressedRepresentation: response.publicKey.data)
			},
			sign: { request in
				@Dependency(\.accountsClient) var accountsClient
				let signers = request.accounts.flatMap(\.keyParams)
				let signaturesRaw = try await makeRequest(
					.signTransaction(.init(
						signers: signers,
						ledgerDevice: .init(from: request.ledger),
						compiledTransactionIntent: .init(data: request.unhashedDataToSign),
						mode: .summary
					)),
					responseCasePath: /P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.signTransaction
				)

				let signatures = try signaturesRaw.map { try $0.parsed() }
				for signer in signers {
					guard signatures.contains(where: {
						$0.derivationPath.path == signer.derivationPath

					}) else {
						throw MissingSignature()
					}
					continue
				}
				let allAccounts = try await accountsClient.getAccountsOnCurrentNetwork()
				var accountSignatures = Set<AccountSignature>()
				//                for signature in signatures {
				//                    guard let accountSignature = allAccounts.compactMap({ account in
				//                        switch account.securityState {
				//                        case let .unsecured(control):
				//                            let factorInstance = control.genesisFactorInstance
				//                            return factorInstance.derivationPath == signature.derivationPath &&
				//                            factorInstance.publicKey == signature.signature.publicKey
				//                        }
//
				//                    }) else {
				//                        throw MissingAccountFromSignatures()
				//                    }
				//                    accountSignatures.insert(accountSignatures)
				//                }
				allAccounts.compactMap { account in

					guard signatures.contains(where: { signature in
						try signature.derivationPath == account.derivationPath()
					}) else {
						return nil
					}
				}
			}
		)
	}()
}

// MARK: - NoDerivationPath
struct NoDerivationPath: Error {}
extension Profile.Network.Account {
	func factorInstance() -> FactorInstance {
		switch securityState {
		case let .unsecured(control):
			return control.genesisFactorInstance
		}
	}

	func derivationPath() throws -> DerivationPath {
		guard let path = factorInstance().derivationPath else {
			throw NoDerivationPath()
		}
		return path
	}

	func publicKey() -> SLIP10.PublicKey {
		factorInstance().publicKey
	}
}

// MARK: - MissingSignature
struct MissingSignature: Swift.Error {}

// MARK: - MissingAccountFromSignatures
struct MissingAccountFromSignatures: Swift.Error {}

// extension Profile.Network.Account {
//    func derivationPath() throws -> DerivationPath {
//        switch securityState {
//        case .unsecured(.)
//        }
//    }
// }

extension P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.SignatureOfSigner {
	struct Parsed: Sendable, Hashable {
		public let signature: SignatureWithPublicKey
		public let derivationPath: DerivationPath
	}

	func parsed() throws -> Parsed {
		guard let curve = SLIP10.Curve(rawValue: self.curve) else {
			struct BadCurve: Swift.Error {}
			throw BadCurve()
		}
		let signatureWithPublicKey: SignatureWithPublicKey
		switch curve {
		case .secp256k1:
			signatureWithPublicKey = try .ecdsaSecp256k1(
				signature: .init(radixFormat: self.signature.data),
				publicKey: .init(compressedRepresentation: self.publicKey.data)
			)
		case .curve25519:
			signatureWithPublicKey = try .eddsaEd25519(
				signature: self.signature.data,
				publicKey: .init(compressedRepresentation: self.publicKey.data)
			)
		}
		let derivationPath: DerivationPath
		do {
			derivationPath = try .init(
				scheme: .cap26,
				path: AccountHierarchicalDeterministicDerivationPath(
					derivationPath: self.derivationPath
				)
				.derivationPath
			)
		} catch {
			derivationPath = try .init(
				scheme: .bip44Olympia,
				path: LegacyOlympiaBIP44LikeDerivationPath(
					derivationPath: self.derivationPath
				)
				.derivationPath
			)
		}

		return Parsed(signature: signatureWithPublicKey, derivationPath: derivationPath)
	}
}

extension Profile.Network.Account {
	var keyParams: [P2P.LedgerHardwareWallet.KeyParameters] {
		switch securityState {
		case let .unsecured(control):
			let factorInstance = control.genesisFactorInstance
			guard let derivationPath = factorInstance.derivationPath else {
				return []
			}
			return [
				.init(
					curve: factorInstance.publicKey.curve.cast(),
					derivationPath: derivationPath.path
				),
			]
		}
	}
}

extension SLIP10.Curve {
	fileprivate func cast() -> P2P.LedgerHardwareWallet.KeyParameters.Curve {
		switch self {
		case .curve25519: return .curve25519
		case .secp256k1: return .secp256k1
		}
	}
}

extension P2P.LedgerHardwareWallet.LedgerDevice {
	init(from factorSource: FactorSource) {
		self.init(
			name: .init(rawValue: factorSource.label.rawValue),
			id: factorSource.id.description,
			model: .init(from: factorSource)
		)
	}
}

extension P2P.LedgerHardwareWallet.Model {
	init(from factorSource: FactorSource) {
		precondition(factorSource.kind == .ledgerHQHardwareWallet)
		self = Self(
			rawValue: factorSource.description.rawValue
		) ?? .nanoSPlus // FIXME: handle optional better.
	}
}

// MARK: - FailedToReceiveAnyResponseFromAnyClient
struct FailedToReceiveAnyResponseFromAnyClient: Swift.Error {}

// MARK: - CasePath + Sendable
extension CasePath: Sendable where Root: Sendable, Value: Sendable {}
