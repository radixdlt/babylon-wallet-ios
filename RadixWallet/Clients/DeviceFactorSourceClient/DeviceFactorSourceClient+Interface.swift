import Sargon

// MARK: - DeviceFactorSourceClient
struct DeviceFactorSourceClient: Sendable {
	var publicKeysFromOnDeviceHD: PublicKeysFromOnDeviceHD
	var signatureFromOnDeviceHD: SignatureFromOnDeviceHD
	var isAccountRecoveryNeeded: IsAccountRecoveryNeeded

	// FIXME: Find a better home for this...
	var entitiesControlledByFactorSource: GetEntitiesControlledByFactorSource

	/// Fetched accounts and personas on current network that are controlled by a device factor source, for every factor source in current profile
	var controlledEntities: GetControlledEntities

	/// The entities (`Accounts` & `Personas`) that are in bad state. This is, that either:
	/// - their mnmemonic is missing (entity was imported but seed phrase never entered), or
	/// - their mnmemonic is not backed up (entity was created but seed phrase never written down).
	var entitiesInBadState: EntitiesInBadState

	init(
		publicKeysFromOnDeviceHD: @escaping PublicKeysFromOnDeviceHD,
		signatureFromOnDeviceHD: @escaping SignatureFromOnDeviceHD,
		isAccountRecoveryNeeded: @escaping IsAccountRecoveryNeeded,
		entitiesControlledByFactorSource: @escaping GetEntitiesControlledByFactorSource,
		controlledEntities: @escaping GetControlledEntities,
		entitiesInBadState: @escaping EntitiesInBadState
	) {
		self.publicKeysFromOnDeviceHD = publicKeysFromOnDeviceHD
		self.signatureFromOnDeviceHD = signatureFromOnDeviceHD
		self.isAccountRecoveryNeeded = isAccountRecoveryNeeded
		self.entitiesControlledByFactorSource = entitiesControlledByFactorSource
		self.controlledEntities = controlledEntities
		self.entitiesInBadState = entitiesInBadState
	}
}

// MARK: DeviceFactorSourceClient.onDeviceHDPublicKey
extension DeviceFactorSourceClient {
	typealias GetEntitiesControlledByFactorSource = @Sendable (DeviceFactorSource, Profile?) async throws -> EntitiesControlledByFactorSource
	typealias GetControlledEntities = @Sendable (Profile?) async throws -> IdentifiedArrayOf<EntitiesControlledByFactorSource>

	typealias PublicKeysFromOnDeviceHD = @Sendable (PublicKeysFromOnDeviceHDRequest) async throws -> [HierarchicalDeterministicPublicKey]
	typealias SignatureFromOnDeviceHD = @Sendable (SignatureFromOnDeviceHDRequest) async throws -> SignatureWithPublicKey
	typealias IsAccountRecoveryNeeded = @Sendable () async throws -> Bool
	typealias EntitiesInBadState = @Sendable () async throws -> AnyAsyncSequence<(withoutControl: AddressesOfEntitiesInBadState, unrecoverable: AddressesOfEntitiesInBadState)>
}

// MARK: - DiscrepancyUnsupportedCurve
struct DiscrepancyUnsupportedCurve: Swift.Error {}

// MARK: - PublicKeysFromOnDeviceHDRequest
struct PublicKeysFromOnDeviceHDRequest: Sendable, Hashable {
	let derivationPaths: [DerivationPath]

	func getMnemonicWithPassphrase() throws -> MnemonicWithPassphrase {
		@Dependency(\.secureStorageClient) var secureStorageClient
		switch source {
		case let .privateHDFactorSource(privateHD):
			return privateHD.mnemonicWithPassphrase
		case let .loadMnemonicFor(deviceFactorSource, loadMnemonicPurpose):
			let factorSourceID = deviceFactorSource.id
			guard
				let mnemonicWithPassphrase = try secureStorageClient.loadMnemonic(factorSourceID: factorSourceID, notifyIfMissing: false)
			else {
				loggerGlobal.critical("Failed to find factor source with ID: '\(factorSourceID)'")
				throw FailedToFindFactorSource()
			}
			return mnemonicWithPassphrase
		}
	}

	enum Source: Sendable, Hashable {
		case privateHDFactorSource(PrivateHierarchicalDeterministicFactorSource)
		case loadMnemonicFor(DeviceFactorSource, purpose: SecureStorageClient.LoadMnemonicPurpose)

		var deviceFactorSource: DeviceFactorSource {
			switch self {
			case let .loadMnemonicFor(deviceFactorSource, _):
				deviceFactorSource
			case let .privateHDFactorSource(privateHDFactorSource):
				privateHDFactorSource.factorSource
			}
		}
	}

	let source: Source
	var deviceFactorSource: DeviceFactorSource {
		source.deviceFactorSource
	}

	init(
		derivationPaths: [DerivationPath],
		source: Source
	) throws {
		for derivationPath in derivationPaths {
			guard source.deviceFactorSource.cryptoParameters.supportedCurves.contains(derivationPath.curve) else {
				throw DiscrepancyUnsupportedCurve()
			}
		}
		self.derivationPaths = derivationPaths
		self.source = source
	}
}

// MARK: - SignatureFromOnDeviceHDRequest
struct SignatureFromOnDeviceHDRequest: Sendable, Hashable {
	let mnemonicWithPassphrase: MnemonicWithPassphrase
	let derivationPath: DerivationPath
	let curve: SLIP10Curve

	/// The data to sign
	let hashedData: Hash
}

// MARK: - FailedToFindDeviceFactorSourceForSigning
struct FailedToFindDeviceFactorSourceForSigning: Swift.Error {}

// MARK: - IncorrectSignatureCountExpectedExactlyOne
struct IncorrectSignatureCountExpectedExactlyOne: Swift.Error {}
extension DeviceFactorSourceClient {
	func signUsingDeviceFactorSource(
		signerEntity: AccountOrPersona,
		hashedDataToSign: Hash,
		purpose: SigningPurpose
	) async throws -> SignatureOfEntity {
		@Dependency(\.factorSourcesClient) var factorSourcesClient
		@Dependency(\.secureStorageClient) var secureStorageClient

		switch signerEntity.securityState {
		case let .unsecured(control):
			let factorInstance = control.transactionSigning

			guard
				let deviceFactorSource = try await factorSourcesClient.getDeviceFactorSource(of: factorInstance)
			else {
				throw FailedToFindDeviceFactorSourceForSigning()
			}

			let signatures = try await signUsingDeviceFactorSource(
				deviceFactorSource: deviceFactorSource,
				signerEntities: [signerEntity],
				hashedDataToSign: hashedDataToSign,
				purpose: purpose
			)

			guard let signature = signatures.first, signatures.count == 1 else {
				throw IncorrectSignatureCountExpectedExactlyOne()
			}
			return signature
		}
	}

	func signUsingDeviceFactorSource(
		deviceFactorSource: DeviceFactorSource,
		signerEntities: Set<AccountOrPersona>,
		hashedDataToSign: Hash,
		purpose: SigningPurpose
	) async throws -> Set<SignatureOfEntity> {
		@Dependency(\.factorSourcesClient) var factorSourcesClient
		@Dependency(\.secureStorageClient) var secureStorageClient

		let factorSourceID = deviceFactorSource.id

		guard
			let loadedMnemonicWithPassphrase = try await secureStorageClient.loadMnemonic(
				factorSourceID: factorSourceID
			)
		else {
			throw FailedToFindDeviceFactorSourceForSigning()
		}

		var signatures = Set<SignatureOfEntity>()

		for entity in signerEntities {
			switch entity.securityState {
			case let .unsecured(unsecuredControl):

				let factorInstance = unsecuredControl.transactionSigning
				let derivationPath = factorInstance.derivationPath

				if factorInstance.factorSourceID != factorSourceID {
					let errMsg = "Discrepancy, you specified to use a device factor source you beleived to be the one controlling the entity, but it does not match the genesis factor source id."
					loggerGlobal.critical(.init(stringLiteral: errMsg))
					assertionFailure(errMsg)
				}
				let curve = factorInstance.publicKey.curve

				loggerGlobal.debug("🔏 Signing data with device, with entity=\(entity.displayName), curve=\(curve), factor source hint.label=\(deviceFactorSource.hint.label), hint.deviceName=\(deviceFactorSource.hint.deviceName), hint.model=\(deviceFactorSource.hint.model)")

				let signatureWithPublicKey = try await self.signatureFromOnDeviceHD(SignatureFromOnDeviceHDRequest(
					mnemonicWithPassphrase: loadedMnemonicWithPassphrase,
					derivationPath: derivationPath,
					curve: curve,
					hashedData: hashedDataToSign
				))

				let entitySignature = SignatureOfEntity(
					signerEntity: entity,
					derivationPath: derivationPath,
					factorSourceID: factorSourceID.asGeneral,
					signatureWithPublicKey: signatureWithPublicKey
				)

				signatures.insert(entitySignature)
			}
		}

		return signatures
	}

	func signTransaction(
		input: PerFactorSourceInputOfTransactionIntent
	) async throws -> [HdSignatureOfTransactionIntentHash] {
		let factorSourceId = input.factorSourceId
		let mnemonicWithPassphrase = try loadMnemonic(factorSourceId: factorSourceId)

		var signatures = Set<HdSignatureOfTransactionIntentHash>()

		for transaction in input.perTransaction {
			let payloadId = transaction.payload.decompile().hash()
			let hashedData = payloadId.hash
			let transactionSignatures = try await sign(
				factorSourceId: factorSourceId,
				mnemonicWithPassphrase: mnemonicWithPassphrase,
				hashedData: hashedData,
				ownedFactorInstances: transaction.ownedFactorInstances
			)

			signatures.formUnion(
				transactionSignatures.map {
					.init(
						input: .init(payloadId: payloadId, ownedFactorInstance: $0.ownedFactorInstance),
						signature: $0.signatureWithPublicKey
					)
				})
		}

		return Array(signatures)
	}

	func signSubintent(
		input: PerFactorSourceInputOfSubintent
	) async throws -> [HdSignatureOfSubintentHash] {
		let factorSourceId = input.factorSourceId
		let mnemonicWithPassphrase = try loadMnemonic(factorSourceId: factorSourceId)

		var signatures = Set<HdSignatureOfSubintentHash>()

		for transaction in input.perTransaction {
			let payloadId = transaction.payload.decompile().hash()
			let hashedData = payloadId.hash
			let transactionSignatures = try await sign(
				factorSourceId: factorSourceId,
				mnemonicWithPassphrase: mnemonicWithPassphrase,
				hashedData: hashedData,
				ownedFactorInstances: transaction.ownedFactorInstances
			)

			signatures.formUnion(
				transactionSignatures.map {
					.init(
						input: .init(payloadId: payloadId, ownedFactorInstance: $0.ownedFactorInstance),
						signature: $0.signatureWithPublicKey
					)
				})
		}

		return Array(signatures)
	}

	func signAuth(
		input: PerFactorSourceInputOfAuthIntent
	) async throws -> [HdSignatureOfAuthIntentHash] {
		let factorSourceId = input.factorSourceId
		let mnemonicWithPassphrase = try loadMnemonic(factorSourceId: factorSourceId)

		var signatures = Set<HdSignatureOfAuthIntentHash>()

		for transaction in input.perTransaction {
			let payloadId = transaction.payload.hash()
			let hashedData = payloadId.payload.hash()

			let transactionSignatures = try await sign(
				factorSourceId: factorSourceId,
				mnemonicWithPassphrase: mnemonicWithPassphrase,
				hashedData: hashedData,
				ownedFactorInstances: transaction.ownedFactorInstances
			)

			signatures.formUnion(
				transactionSignatures.map {
					.init(
						input: .init(payloadId: payloadId, ownedFactorInstance: $0.ownedFactorInstance),
						signature: $0.signatureWithPublicKey
					)
				})
		}

		return Array(signatures)
	}

	private func loadMnemonic(factorSourceId: FactorSourceIdFromHash) throws -> MnemonicWithPassphrase {
		@Dependency(\.secureStorageClient) var secureStorageClient

		guard
			let mnemonicWithPassphrase = try secureStorageClient.loadMnemonic(factorSourceID: factorSourceId)
		else {
			throw FailedToFindDeviceFactorSourceForSigning()
		}
		return mnemonicWithPassphrase
	}

	private func sign(
		factorSourceId: FactorSourceIDFromHash,
		mnemonicWithPassphrase: MnemonicWithPassphrase,
		hashedData: Hash,
		ownedFactorInstances: [OwnedFactorInstance]
	) async throws -> Set<SignatureOfEntity2> {
		var signatures = Set<SignatureOfEntity2>()

		for ownedFactorInstance in ownedFactorInstances {
			let factorInstance = ownedFactorInstance.factorInstance
			let derivationPath = factorInstance.derivationPath

			if factorInstance.factorSourceID != factorSourceId {
				let errMsg = "Discrepancy, you specified to use a device factor source you beleived to be the one controlling the entity, but it does not match the genesis factor source id."
				loggerGlobal.critical(.init(stringLiteral: errMsg))
				assertionFailure(errMsg)
			}
			let curve = factorInstance.publicKey.curve

			let signatureWithPublicKey = try await self.signatureFromOnDeviceHD(SignatureFromOnDeviceHDRequest(
				mnemonicWithPassphrase: mnemonicWithPassphrase,
				derivationPath: derivationPath,
				curve: curve,
				hashedData: hashedData
			))

			signatures.insert(.init(ownedFactorInstance: ownedFactorInstance, signatureWithPublicKey: signatureWithPublicKey))
		}

		return signatures
	}
}

extension SigningPurpose {
	var loadMnemonicPurpose: SecureStorageClient.LoadMnemonicPurpose {
		switch self {
		case .signAuth:
			return .signAuthChallenge
		case .signTransaction(.manifestFromDapp):
			return .signTransaction
		case .signTransaction(.internalManifest(.transfer)):
			return .signTransaction
		case let .signTransaction(.internalManifest(.uploadAuthKey(forEntityKind))):
			return .createSignAuthKey(forEntityKind: forEntityKind)
		#if DEBUG
		case .signTransaction(.internalManifest(.debugModifyAccount)):
			return .updateAccountMetadata
		#endif // DEBUG
		case .signPreAuthorization:
			return .signTransaction
		}
	}
}

// MARK: - FactorInstanceDoesNotHaveADerivationPathUnableToSign
struct FactorInstanceDoesNotHaveADerivationPathUnableToSign: Swift.Error {}

extension DeviceFactorSourceHint {
	var name: String {
		label
	}
}

extension LedgerHardwareWalletHint {
	var name: String {
		label
	}
}
