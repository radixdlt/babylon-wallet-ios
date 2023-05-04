import ClientPrelude
import ComposableArchitecture // actually CasePaths... but CI fails if we do `import CasePaths` 🤷‍♂️
import Cryptography
import EngineToolkit
import FactorSourcesClient
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
						ledgerDevice: .init(factorSource: factorSource)
					)),
					responseCasePath: /P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.derivePublicKey
				)

				return try .init(compressedRepresentation: response.publicKey.data)
			},
			sign: { request in

				let signaturesRaw = try await makeRequest(
					.signTransaction(.init(
						signers: request.signingFactor.signers.flatMap(\.keyParams),
						ledgerDevice: .init(factorSource: request.signingFactor.factorSource),
						compiledTransactionIntent: .init(data: request.unhashedDataToSign),
						displayHash: request.displayHashOnLedgerDisplay,
						mode: request.ledgerTXDisplayMode
					)),
					responseCasePath: /P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.signTransaction
				)
				let hashedMsg = try blake2b(data: request.unhashedDataToSign)
				let signaturesValidated = try signaturesRaw.map { try $0.validate(hashed: hashedMsg) }
				var accountSignatures = Set<AccountSignature>()

				for requiredSigner in request.signingFactor.signers {
					for requiredSigningFactor in requiredSigner.factorInstancesRequiredToSign {
						guard
							let signature = signaturesValidated.first(where: {
								$0.signature.publicKey == requiredSigningFactor.publicKey
							})
						else {
							loggerGlobal.error("Missing signature from required signer with publicKey: \(requiredSigningFactor.publicKey.compressedRepresentation.hex)")
							throw MissingAccountFromSignatures()
						}
						assert(requiredSigningFactor.derivationPath == signature.derivationPath)
						let accountSignature = try AccountSignature(
							account: requiredSigner.account,
							signature: signature
						)
						accountSignatures.insert(accountSignature)
					}
				}

				return accountSignatures
			}
		)
	}()
}

extension AccountSignature {
	init(
		account: Profile.Network.Account,
		signature signatureParsed: P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.SignatureOfSigner.Validated
	) throws {
		switch account.securityState {
		case let .unsecured(unsecuredEntityControl):
			let signature = try Signature(
				signatureWithPublicKey: signatureParsed.signature,
				derivationPath: unsecuredEntityControl.transactionSigning.derivationPathOrThrow()
			)
			try self.init(
				entity: account,
				factorInstance: unsecuredEntityControl.transactionSigning,
				signature: signature
			)
		}
	}
}

// MARK: - MissingAccountFromSignatures
struct MissingAccountFromSignatures: Swift.Error {}

extension P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.SignatureOfSigner {
	struct Validated: Sendable, Hashable {
		public let signature: SignatureWithPublicKey
		public let derivationPath: DerivationPath
	}

	func validate(hashed: Data) throws -> Validated {
		guard let curve = SLIP10.Curve(rawValue: self.curve) else {
			struct BadCurve: Swift.Error {}
			loggerGlobal.error("Bad curve")
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
				path: AccountBabylonDerivationPath(
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

		guard signatureWithPublicKey.isValidSignature(for: hashed) else {
			loggerGlobal.error("Signature invalid for hashed msg: \(hashed.hex), signatureWithPublicKey: \(signatureWithPublicKey)")
			throw InvalidSignature()
		}

		return Validated(
			signature: signatureWithPublicKey,
			derivationPath: derivationPath
		)
	}
}

// MARK: - InvalidSignature
struct InvalidSignature: Swift.Error {}

extension SigningFactor.Signer {
	var keyParams: [P2P.LedgerHardwareWallet.KeyParameters] {
		factorInstancesRequiredToSign.compactMap {
			guard let derivationPath = $0.derivationPath else {
				loggerGlobal.warning("Found factor instance without derivation path to be used as signer with Ledger, this is not supported, ignoring it. Probably something wrong somewhere.")
				return nil
			}
			return P2P.LedgerHardwareWallet.KeyParameters(
				curve: $0.publicKey.curve.cast(),
				derivationPath: derivationPath.path
			)
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
	public init(factorSource: FactorSource) {
		self.init(
			name: .init(rawValue: factorSource.label.rawValue),
			id: factorSource.id.description,
			model: .init(from: factorSource)
		)
	}
}

extension P2P.LedgerHardwareWallet.Model {
	public init(from factorSource: FactorSource) {
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
