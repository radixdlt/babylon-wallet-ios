import ClientPrelude
import ComposableArchitecture // actually CasePaths... but CI fails if we do `import CasePaths` 🤷‍♂️
import Cryptography
import EngineToolkit
import FactorSourcesClient
import Profile
import RadixConnectClient
import ROLAClient

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

			loggerGlobal.debug("About to broadcast \(request.discriminator.rawValue) request with interactionID: \(interactionID)..")

			var clientsLeftToReceiveAnswerFrom = try await radixConnectClient
				.sendRequest(.connectorExtension(.ledgerHardwareWallet(.init(interactionID: interactionID, request: request))), .broadcastToAllPeers)

			loggerGlobal.debug("Broadcasted \(request.discriminator.rawValue) request with interactionID: \(interactionID) ✅ waiting for response")

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

		@Sendable func sign(
			signers: NonEmpty<IdentifiedArrayOf<Signer>>,
			expectedHashedMessage: Data,
			signOnLedgerRequest: () async throws -> [P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.SignatureOfSigner]
		) async throws -> Set<SignatureOfEntity> {
			let signaturesRaw = try await signOnLedgerRequest()

			let signaturesValidated = try signaturesRaw.map { try $0.validate(hashed: expectedHashedMessage) }
			var signatures = Set<SignatureOfEntity>()

			let signerEntities = Set(signers.map(\.entity))

			for requiredSigner in signers {
				for requiredSigningFactor in requiredSigner.factorInstancesRequiredToSign {
					guard
						let signature = signaturesValidated.first(where: {
							$0.signature.publicKey == requiredSigningFactor.publicKey
						})
					else {
						loggerGlobal.error("Missing signature from required signer with publicKey: \(requiredSigningFactor.publicKey.compressedRepresentation.hex)")
						throw MissingSignatureFromRequiredSigner()
					}
					assert(requiredSigningFactor.derivationPath == signature.derivationPath)

					let entitySignature = SignatureOfEntity(
						signerEntity: requiredSigner.entity,
						derivationPath: signature.derivationPath,
						factorSourceID: requiredSigningFactor.factorSourceID,
						signatureWithPublicKey: signature.signature
					)

					signatures.insert(entitySignature)
				}
			}

			return signatures
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
			derivePublicKeys: { keysParams, factorSource in
				let response = try await makeRequest(
					.derivePublicKeys(.init(
						keysParameters: Array(keysParams),
						ledgerDevice: factorSource.device()
					)),
					responseCasePath: /P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.derivePublicKeys
				)

				return try OrderedSet(validating: response.map {
					try $0.hdPubKey()
				})
			},
			signTransaction: { request in
				let hashedMsg = try blake2b(data: request.unhashedDataToSign)
				return try await sign(
					signers: request.signers,
					expectedHashedMessage: hashedMsg
				) {
					try await makeRequest(
						.signTransaction(.init(
							signers: request.signers.flatMap(\.keyParams),
							ledgerDevice: request.ledger.device(),
							compiledTransactionIntent: .init(data: request.unhashedDataToSign),
							displayHash: request.displayHashOnLedgerDisplay,
							mode: request.ledgerTXDisplayMode
						)),
						responseCasePath: /P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.signTransaction
					)
				}
			},
			signAuthChallenge: { request in
				@Dependency(\.rolaClient) var rolaClient

				let rolaPayload = try rolaClient.authenticationDataToSignForChallenge(.init(
					challenge: request.challenge,
					origin: request.origin,
					dAppDefinitionAddress: request.dAppDefinitionAddress
				))
				let hash = try blake2b(data: rolaPayload.payloadToHashAndSign)
				return try await sign(
					signers: request.signers,
					expectedHashedMessage: hash
				) {
					try await makeRequest(
						.signChallenge(.init(
							signers: request.signers.flatMap(\.keyParams),
							ledgerDevice: request.ledger.device(),
							challenge: request.challenge,
							origin: request.origin,
							dAppDefinitionAddress: request.dAppDefinitionAddress
						)),
						responseCasePath: /P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.signChallenge
					)
				}
			}
		)
	}()
}

extension LedgerFactorSource {
	func device() throws -> P2P.LedgerHardwareWallet.LedgerDevice {
		guard let model = P2P.LedgerHardwareWallet.Model(rawValue: model.rawValue) else {
			throw UnrecognizedLedgerModel(model: model.rawValue)
		}
		return P2P.LedgerHardwareWallet.LedgerDevice(
			name: NonEmptyString(maybeString: self.name),
			id: factorSource.id.hex(),
			model: model
		)
	}
}

extension P2P.LedgerHardwareWallet.LedgerDevice {
	public init(factorSource: FactorSource) throws {
		self = try LedgerFactorSource(factorSource: factorSource).device()
	}
}

// MARK: - MissingSignatureFromRequiredSigner
public struct MissingSignatureFromRequiredSigner: Swift.Error {}

// MARK: - FailedToFindFactorInstanceMatchingDerivationPathInSignature
public struct FailedToFindFactorInstanceMatchingDerivationPathInSignature: Swift.Error {}

extension P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.DerivedPublicKey {
	public func hdPubKey() throws -> HierarchicalDeterministicPublicKey {
		guard let curve = SLIP10.Curve(rawValue: self.curve) else {
			struct BadCurve: Swift.Error {}
			loggerGlobal.error("Bad curve")
			throw BadCurve()
		}
		let publicKey: SLIP10.PublicKey
		switch curve {
		case .secp256k1:
			publicKey = try .ecdsaSecp256k1(.init(compressedRepresentation: self.publicKey.data))
		case .curve25519:
			publicKey = try .eddsaEd25519(.init(compressedRepresentation: self.publicKey.data))
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

		assert(derivationPath.curveForScheme == curve)

		return .init(publicKey: publicKey, derivationPath: derivationPath)
	}
}

extension P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.SignatureOfSigner {
	struct Validated: Sendable, Hashable {
		public let signature: SignatureWithPublicKey
		public let derivationPath: DerivationPath
	}

	func validate(hashed: Data) throws -> Validated {
		let hdPubKey = try self.derivedPublicKey.hdPubKey()
		let signatureWithPublicKey: SignatureWithPublicKey
		switch hdPubKey.publicKey {
		case let .ecdsaSecp256k1(pubKey):
			signatureWithPublicKey = try .ecdsaSecp256k1(
				signature: .init(radixFormat: self.signature.data),
				publicKey: pubKey
			)
		case let .eddsaEd25519(pubKey):
			signatureWithPublicKey = .eddsaEd25519(
				signature: self.signature.data,
				publicKey: pubKey
			)
		}

		guard signatureWithPublicKey.isValidSignature(for: hashed) else {
			loggerGlobal.error("Signature invalid for hashed msg: \(hashed.hex), signatureWithPublicKey: \(signatureWithPublicKey)")
			throw InvalidSignature()
		}

		return Validated(
			signature: signatureWithPublicKey,
			derivationPath: hdPubKey.derivationPath
		)
	}
}

// MARK: - InvalidSignature
struct InvalidSignature: Swift.Error {}

extension Signer {
	var keyParams: [P2P.LedgerHardwareWallet.KeyParameters] {
		factorInstancesRequiredToSign.compactMap {
			P2P.LedgerHardwareWallet.KeyParameters(
				curve: $0.publicKey.curve.cast(),
				derivationPath: $0.derivationPath.path
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

// MARK: - FailedToReceiveAnyResponseFromAnyClient
struct FailedToReceiveAnyResponseFromAnyClient: Swift.Error {}

// MARK: - CasePath + Sendable
extension CasePath: Sendable where Root: Sendable, Value: Sendable {}
