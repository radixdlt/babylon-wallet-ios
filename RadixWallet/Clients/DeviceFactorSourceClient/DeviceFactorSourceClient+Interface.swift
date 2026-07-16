import Sargon

// MARK: - DeviceFactorSourceClient
struct DeviceFactorSourceClient {
	/// The entities (`Accounts` & `Personas`) that are in bad state. This is, that either:
	/// - their mnmemonic is missing (entity was imported but seed phrase never entered), or
	/// - their mnmemonic is not backed up (entity was created but seed phrase never written down).
	var entitiesInBadState: EntitiesInBadState

	var loadMnemonic: LoadMnemonic
}

// MARK: - DeviceFactorSourceClient
extension DeviceFactorSourceClient {
	typealias EntitiesInBadState = @Sendable () async throws -> AnyAsyncSequence<(withoutControl: AddressesOfEntitiesInBadState, unrecoverable: AddressesOfEntitiesInBadState)>
	typealias LoadMnemonic = @Sendable (FactorSourceIdFromHash) throws -> MnemonicWithPassphrase
}

// MARK: - DeviceMnemonicLoadError
enum DeviceMnemonicLoadError: Error, Hashable {
	/// The user explicitly cancelled native authentication or Keychain access.
	case cancelledByUser

	/// Secure storage conclusively contains no mnemonic for the factor source.
	case missing

	/// Secure storage may contain a mnemonic, but it could not be read or decoded.
	case readFailure
}

// MARK: - MnemonicWithPassphrase
extension MnemonicWithPassphrase {
	func signTransaction(
		input: PerFactorSourceInputOfTransactionIntent
	) -> [HdSignatureOfTransactionIntentHash] {
		let factorSourceId = input.factorSourceId

		var signatures = Set<HdSignatureOfTransactionIntentHash>()

		for transaction in input.perTransaction {
			let payloadId = transaction.payload.decompile().hash()
			let hashedData = payloadId.hash
			let transactionSignatures = sign(
				factorSourceId: factorSourceId,
				hashedData: hashedData,
				ownedFactorInstances: transaction.ownedFactorInstances
			)

			signatures.formUnion(
				transactionSignatures.map {
					.init(
						input: .init(payloadId: payloadId, ownedFactorInstance: $0.ownedFactorInstance),
						signature: $0.signatureWithPublicKey
					)
				}
			)
		}

		return Array(signatures)
	}

	func signSubintent(
		input: PerFactorSourceInputOfSubintent
	) -> [HdSignatureOfSubintentHash] {
		let factorSourceId = input.factorSourceId
		var signatures = Set<HdSignatureOfSubintentHash>()

		for transaction in input.perTransaction {
			let payloadId = transaction.payload.decompile().hash()
			let hashedData = payloadId.hash
			let transactionSignatures = sign(
				factorSourceId: factorSourceId,
				hashedData: hashedData,
				ownedFactorInstances: transaction.ownedFactorInstances
			)

			signatures.formUnion(
				transactionSignatures.map {
					.init(
						input: .init(payloadId: payloadId, ownedFactorInstance: $0.ownedFactorInstance),
						signature: $0.signatureWithPublicKey
					)
				}
			)
		}

		return Array(signatures)
	}

	func signAuth(
		input: PerFactorSourceInputOfAuthIntent
	) -> [HdSignatureOfAuthIntentHash] {
		let factorSourceId = input.factorSourceId
		var signatures = Set<HdSignatureOfAuthIntentHash>()

		for transaction in input.perTransaction {
			let payloadId = transaction.payload.hash()
			let hashedData = payloadId.payload.hash()

			let transactionSignatures = sign(
				factorSourceId: factorSourceId,
				hashedData: hashedData,
				ownedFactorInstances: transaction.ownedFactorInstances
			)

			signatures.formUnion(
				transactionSignatures.map {
					.init(
						input: .init(payloadId: payloadId, ownedFactorInstance: $0.ownedFactorInstance),
						signature: $0.signatureWithPublicKey
					)
				}
			)
		}

		return Array(signatures)
	}

	func sign(
		factorSourceId: FactorSourceIDFromHash,
		hashedData: Hash,
		ownedFactorInstances: [OwnedFactorInstance]
	) -> Set<SignatureOfEntity> {
		var signatures = Set<SignatureOfEntity>()

		for ownedFactorInstance in ownedFactorInstances {
			let factorInstance = ownedFactorInstance.factorInstance
			if factorInstance.factorSourceID != factorSourceId {
				let errMsg = "Discrepancy, you specified to use a device factor source you beleived to be the one controlling the entity, but it does not match the genesis factor source id."
				loggerGlobal.critical(.init(stringLiteral: errMsg))
				assertionFailure(errMsg)
			}

			let signatureWithPublicKey = sign(hash: hashedData, path: factorInstance.derivationPath)

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
