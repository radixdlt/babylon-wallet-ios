import ComposableArchitecture // actually CasePaths... but CI fails if we do `import CasePaths` 🤷‍♂️
import Sargon

// MARK: - LedgerHardwareWalletClient + DependencyKey
extension LedgerHardwareWalletClient: DependencyKey {
	typealias Value = LedgerHardwareWalletClient

	static let liveValue: Self = {
		@Dependency(\.radixConnectClient) var radixConnectClient

		@Dependency(\.overlayWindowClient) var overlayWindowClient
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

					switch errorFromConnectorExtension.code {
					case .generic, .userRejectedSigningOfTransaction: break
					case .blindSigningNotEnabledButRequired:
						overlayWindowClient.scheduleAlertAndIgnoreAction(
							.init(
								title: {
									TextState(L10n.LedgerHardwareDevices.CouldNotSign.title)
								},
								message: {
									TextState(L10n.LedgerHardwareDevices.CouldNotSign.message)
								}
							)
						)
					}

					throw errorFromConnectorExtension
				}

				clientsLeftToReceiveAnswerFrom -= 1
			}

			throw FailedToReceiveAnyResponseFromAnyClient()
		}

		let derivePublicKeys: DerivePublicKeys = { request in
			try await makeRequest(
				.derivePublicKeys(.init(
					keysParameters: request.input.derivationPaths.map(\.keyParams),
					ledgerDevice: request.ledger.device()
				)),
				responseCasePath: /P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.derivePublicKeys
			)
			.map {
				try $0.hdPubKey()
			}
			.map {
				.init(factorSourceId: request.input.factorSourceId, publicKey: $0)
			}
		}

		@Sendable func sign(
			expectedHashedMessage: Data,
			ownedFactorInstances: [OwnedFactorInstance],
			signOnLedgerRequest: () async throws -> [P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.SignatureOfSigner]
		) async throws -> Set<SignatureOfEntity> {
			let signaturesRaw = try await signOnLedgerRequest()

			let signaturesValidated = try signaturesRaw.map { try $0.validate(hashed: expectedHashedMessage) }
			var signatures = Set<SignatureOfEntity>()

			for ownedFactorInstance in ownedFactorInstances {
				let factorInstance = ownedFactorInstance.factorInstance
				guard let signature = signaturesValidated.first(where: {
					$0.signature.publicKey == factorInstance.publicKey.publicKey
				}) else {
					loggerGlobal.error("Missing signature from required signer with publicKey: \(factorInstance.publicKey.publicKey.hex)")
					throw MissingSignatureFromRequiredSigner()
				}
				assert(factorInstance.derivationPath == signature.derivationPath)

				signatures.insert(.init(ownedFactorInstance: ownedFactorInstance, signatureWithPublicKey: signature.signature))
			}

			return signatures
		}

		let signTransaction: SignTransaction = { request in
			let compiledIntent = request.input.payload
			let payloadId = compiledIntent.decompile().hash()
			let expectedHashedMessage = payloadId.hash.data

			let result = try await sign(
				expectedHashedMessage: expectedHashedMessage,
				ownedFactorInstances: request.input.ownedFactorInstances
			) {
				try await makeRequest(
					.signTransaction(.init(
						signers: request.input.ownedFactorInstances.map(\.keyParams),
						ledgerDevice: request.ledger.device(),
						compiledTransactionIntent: .init(data: compiledIntent.data),
						displayHash: false
					)),
					responseCasePath: /P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.signTransaction
				)
			}

			return result.map { item in
				.init(input: .init(payloadId: payloadId, ownedFactorInstance: item.ownedFactorInstance), signature: item.signatureWithPublicKey)
			}
		}

		let signSubintent: SignSubintent = { request in
			let compiledSubintent = request.input.payload
			let payloadId = compiledSubintent.decompile().hash()
			let expectedHashedMessage = payloadId.hash.data

			let result = try await sign(
				expectedHashedMessage: expectedHashedMessage,
				ownedFactorInstances: request.input.ownedFactorInstances
			) {
				try await makeRequest(
					.signSubintentHash(.init(
						signers: request.input.ownedFactorInstances.map(\.keyParams),
						ledgerDevice: request.ledger.device(),
						subintentHash: .init(data: expectedHashedMessage)
					)),
					responseCasePath: /P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.signSubintentHash
				)
			}

			return result.map { item in
				.init(input: .init(payloadId: payloadId, ownedFactorInstance: item.ownedFactorInstance), signature: item.signatureWithPublicKey)
			}
		}

		let signAuth: SignAuth = { request in
			let payload = request.input.payload
			let payloadId = payload.hash()
			let expectedHashedMessage = payloadId.payload.hash().data

			let result = try await sign(
				expectedHashedMessage: expectedHashedMessage,
				ownedFactorInstances: request.input.ownedFactorInstances
			) {
				try await makeRequest(
					.signChallenge(.init(
						signers: request.input.ownedFactorInstances.map(\.keyParams),
						ledgerDevice: request.ledger.device(),
						challenge: payload.challengeNonce,
						origin: payload.origin,
						dAppDefinitionAddress: payload.dappDefinitionAddress
					)),
					responseCasePath: /P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.signChallenge
				)
			}

			return result.map { item in
				.init(input: .init(payloadId: payloadId, ownedFactorInstance: item.ownedFactorInstance), signature: item.signatureWithPublicKey)
			}
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
			derivePublicKeys: derivePublicKeys,
			signTransaction: signTransaction,
			signSubintent: signSubintent,
			signAuth: signAuth,
			deriveAndDisplayAddress: { keyParams, factorSource in
				let response = try await makeRequest(
					.deriveAndDisplayAddress(.init(
						keyParameters: keyParams,
						ledgerDevice: factorSource.device()
					)),
					responseCasePath: /P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.deriveAndDisplayAddress
				)

				return try (response.derivedKey.hdPubKey(), address: response.address)
			}
		)
	}()
}

extension LedgerHardwareWalletFactorSource {
	func device() throws -> P2P.LedgerHardwareWallet.LedgerDevice {
		guard let model = P2P.LedgerHardwareWallet.Model(rawValue: hint.model.rawValue) else {
			throw UnrecognizedLedgerModel(model: hint.model.rawValue)
		}

		return P2P.LedgerHardwareWallet.LedgerDevice(
			name: NonEmptyString(maybeString: hint.label),
			id: id.body.data.data.hex,
			model: model
		)
	}
}

// MARK: - UnrecognizedLedgerModel
struct UnrecognizedLedgerModel: Error {
	let model: String
	init(model: String) {
		self.model = model
	}
}

extension P2P.LedgerHardwareWallet.LedgerDevice {
	init(factorSource: FactorSource) throws {
		self = try factorSource.extract(as: LedgerHardwareWalletFactorSource.self).device()
	}
}

// MARK: - MissingSignatureFromRequiredSigner
struct MissingSignatureFromRequiredSigner: Swift.Error {}

// MARK: - FailedToFindFactorInstanceMatchingDerivationPathInSignature
struct FailedToFindFactorInstanceMatchingDerivationPathInSignature: Swift.Error {}

extension P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.SignatureOfSigner {
	struct Validated: Sendable, Hashable {
		let signature: SignatureWithPublicKey
		let derivationPath: DerivationPath
	}

	func validate(hashed: Data) throws -> Validated {
		let hdPubKey = try self.derivedPublicKey.hdPubKey()
		let signatureWithPublicKey: SignatureWithPublicKey = switch hdPubKey.publicKey {
		case let .secp256k1(pubKey):
			try .secp256k1(
				publicKey: pubKey,
				signature: .init(bytes: self.signature.data)
			)
		case let .ed25519(pubKey):
			try .ed25519(
				publicKey: pubKey,
				signature: .init(bytes: self.signature.data)
			)
		}

		let bytes32 = try Exactly32Bytes(bytes: hashed)
		let hash = Hash(bytes32: bytes32)
		let isValidSignature = signatureWithPublicKey.isValid(hash)

		guard isValidSignature else {
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

// TODO: Delete
extension Signer {
	var keyParams: [P2P.LedgerHardwareWallet.KeyParameters] {
		factorInstancesRequiredToSign.compactMap {
			P2P.LedgerHardwareWallet.KeyParameters(
				curve: $0.publicKey.curve.toLedger(),
				derivationPath: $0.derivationPath.toString()
			)
		}
	}
}

// MARK: - FailedToReceiveAnyResponseFromAnyClient
struct FailedToReceiveAnyResponseFromAnyClient: Swift.Error {}

// MARK: - CasePath + Sendable
extension CasePath: Sendable where Root: Sendable, Value: Sendable {}

private extension OwnedFactorInstance {
	var keyParams: P2P.LedgerHardwareWallet.KeyParameters {
		factorInstance.derivationPath.keyParams
	}
}

private extension DerivationPath {
	var keyParams: P2P.LedgerHardwareWallet.KeyParameters {
		.init(
			curve: curve.toLedger(),
			derivationPath: toBip32String()
		)
	}
}
