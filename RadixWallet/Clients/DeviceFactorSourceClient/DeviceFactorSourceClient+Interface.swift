import Sargon

// MARK: - DeviceFactorSourceClient
struct DeviceFactorSourceClient: Sendable {
	var isAccountRecoveryNeeded: IsAccountRecoveryNeeded

	// FIXME: Find a better home for this...
	var entitiesControlledByFactorSource: GetEntitiesControlledByFactorSource

	/// Fetched accounts and personas on current network that are controlled by a device factor source, for every factor source in current profile
	var controlledEntities: GetControlledEntities

	/// The entities (`Accounts` & `Personas`) that are in bad state. This is, that either:
	/// - their mnmemonic is missing (entity was imported but seed phrase never entered), or
	/// - their mnmemonic is not backed up (entity was created but seed phrase never written down).
	var entitiesInBadState: EntitiesInBadState

	var derivePublicKeys: DerivePublicKeys
}

// MARK: DeviceFactorSourceClient.onDeviceHDPublicKey
extension DeviceFactorSourceClient {
	typealias GetEntitiesControlledByFactorSource = @Sendable (DeviceFactorSource, Profile?) async throws -> EntitiesControlledByFactorSource
	typealias GetControlledEntities = @Sendable (Profile?) async throws -> IdentifiedArrayOf<EntitiesControlledByFactorSource>

	typealias IsAccountRecoveryNeeded = @Sendable () async throws -> Bool
	typealias EntitiesInBadState = @Sendable () async throws -> AnyAsyncSequence<(withoutControl: AddressesOfEntitiesInBadState, unrecoverable: AddressesOfEntitiesInBadState)>
	typealias DerivePublicKeys = @Sendable (KeyDerivationRequestPerFactorSource) async throws -> [HierarchicalDeterministicFactorInstance]
}

// MARK: - FailedToFindDeviceFactorSourceForSigning
struct FailedToFindDeviceFactorSourceForSigning: Swift.Error {}

// MARK: - IncorrectSignatureCountExpectedExactlyOne
struct IncorrectSignatureCountExpectedExactlyOne: Swift.Error {}
extension DeviceFactorSourceClient {
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
	) async throws -> Set<SignatureOfEntity> {
		var signatures = Set<SignatureOfEntity>()

		for ownedFactorInstance in ownedFactorInstances {
			let factorInstance = ownedFactorInstance.factorInstance
			if factorInstance.factorSourceID != factorSourceId {
				let errMsg = "Discrepancy, you specified to use a device factor source you beleived to be the one controlling the entity, but it does not match the genesis factor source id."
				loggerGlobal.critical(.init(stringLiteral: errMsg))
				assertionFailure(errMsg)
			}

			let signatureWithPublicKey = mnemonicWithPassphrase.sign(hash: hashedData, path: factorInstance.derivationPath)

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
