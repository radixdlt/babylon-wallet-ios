import ClientPrelude
import EngineKit
import struct Profile.Signer

// MARK: - FactorSourcesClient
public struct FactorSourcesClient: Sendable {
	public var getCurrentNetworkID: GetCurrentNetworkID
	public var getFactorSources: GetFactorSources
	public var factorSourcesAsyncSequence: FactorSourcesAsyncSequence
	public var addPrivateHDFactorSource: AddPrivateHDFactorSource
	public var checkIfHasOlympiaFactorSourceForAccounts: CheckIfHasOlympiaFactorSourceForAccounts
	public var saveFactorSource: SaveFactorSource
	public var updateFactorSource: UpdateFactorSource
	public var getSigningFactors: GetSigningFactors
	public var updateLastUsed: UpdateLastUsed
	public var flagFactorSourceForDeletion: FlagFactorSourceForDeletion

	public init(
		getCurrentNetworkID: @escaping GetCurrentNetworkID,
		getFactorSources: @escaping GetFactorSources,
		factorSourcesAsyncSequence: @escaping FactorSourcesAsyncSequence,
		addPrivateHDFactorSource: @escaping AddPrivateHDFactorSource,
		checkIfHasOlympiaFactorSourceForAccounts: @escaping CheckIfHasOlympiaFactorSourceForAccounts,
		saveFactorSource: @escaping SaveFactorSource,
		updateFactorSource: @escaping UpdateFactorSource,
		getSigningFactors: @escaping GetSigningFactors,
		updateLastUsed: @escaping UpdateLastUsed,
		flagFactorSourceForDeletion: @escaping FlagFactorSourceForDeletion
	) {
		self.getCurrentNetworkID = getCurrentNetworkID
		self.getFactorSources = getFactorSources
		self.factorSourcesAsyncSequence = factorSourcesAsyncSequence
		self.addPrivateHDFactorSource = addPrivateHDFactorSource
		self.checkIfHasOlympiaFactorSourceForAccounts = checkIfHasOlympiaFactorSourceForAccounts
		self.saveFactorSource = saveFactorSource
		self.updateFactorSource = updateFactorSource
		self.getSigningFactors = getSigningFactors
		self.updateLastUsed = updateLastUsed
		self.flagFactorSourceForDeletion = flagFactorSourceForDeletion
	}
}

// MARK: FactorSourcesClient.GetFactorSources
extension FactorSourcesClient {
	public typealias GetCurrentNetworkID = @Sendable () async -> NetworkID
	public typealias GetFactorSources = @Sendable () async throws -> FactorSources
	public typealias FactorSourcesAsyncSequence = @Sendable () async -> AnyAsyncSequence<FactorSources>
	public typealias AddPrivateHDFactorSource = @Sendable (AddPrivateHDFactorSourceRequest) async throws -> FactorSourceID
	public typealias CheckIfHasOlympiaFactorSourceForAccounts = @Sendable (NonEmpty<OrderedSet<OlympiaAccountToMigrate>>) async -> FactorSourceID.FromHash?
	public typealias SaveFactorSource = @Sendable (FactorSource) async throws -> Void
	public typealias UpdateFactorSource = @Sendable (FactorSource) async throws -> Void
	public typealias GetSigningFactors = @Sendable (GetSigningFactorsRequest) async throws -> SigningFactors
	public typealias UpdateLastUsed = @Sendable (UpdateFactorSourceLastUsedRequest) async throws -> Void
	public typealias FlagFactorSourceForDeletion = @Sendable (FactorSourceID) async throws -> Void
}

// MARK: - AddPrivateHDFactorSourceRequest
public struct AddPrivateHDFactorSourceRequest: Sendable, Hashable {
	public let factorSource: FactorSource
	public let mnemonicWithPasshprase: MnemonicWithPassphrase
	/// E.g. import babylon factor sources should only be saved keychain, not profile (already there).
	public let saveIntoProfile: Bool
	public init(factorSource: FactorSource, mnemonicWithPasshprase: MnemonicWithPassphrase, saveIntoProfile: Bool) {
		self.factorSource = factorSource
		self.mnemonicWithPasshprase = mnemonicWithPasshprase
		self.saveIntoProfile = saveIntoProfile
	}
}

public typealias SigningFactors = OrderedDictionary<FactorSourceKind, NonEmpty<Set<SigningFactor>>>

extension SigningFactors {
	public var expectedSignatureCount: Int {
		values.flatMap { $0.map(\.expectedSignatureCount) }.reduce(0, +)
	}
}

// MARK: - GetSigningFactorsRequest
public struct GetSigningFactorsRequest: Sendable, Hashable {
	public let networkID: NetworkID
	public let signers: NonEmpty<Set<EntityPotentiallyVirtual>>
	public let signingPurpose: SigningPurpose
	public init(networkID: NetworkID, signers: NonEmpty<Set<EntityPotentiallyVirtual>>, signingPurpose: SigningPurpose) {
		self.networkID = networkID
		self.signers = signers
		self.signingPurpose = signingPurpose
	}
}

extension FactorSourcesClient {
	public func getFactorSource(
		id: FactorSourceID,
		matching filter: @escaping (FactorSource) -> Bool = { _ in true }
	) async throws -> FactorSource? {
		try await getFactorSources(matching: filter)[id: id]
	}

	public func getDeviceFactorSource(
		of hdFactorInstance: HierarchicalDeterministicFactorInstance
	) async throws -> DeviceFactorSource? {
		guard let factorSource = try await getFactorSource(of: hdFactorInstance.factorInstance) else {
			return nil
		}
		return try factorSource.extract(as: DeviceFactorSource.self)
	}

	public func getFactorSource<Source: FactorSourceProtocol>(
		id: FactorSourceID,
		as _: Source.Type
	) async throws -> Source? {
		try await getFactorSource(id: id)?.extract(Source.self)
	}

	public func getFactorSource(
		of factorInstance: FactorInstance
	) async throws -> FactorSource? {
		try await getFactorSource(id: factorInstance.factorSourceID)
	}

	public func getFactorSources(
		matching filter: (FactorSource) -> Bool
	) async throws -> IdentifiedArrayOf<FactorSource> {
		try await IdentifiedArrayOf(uniqueElements: getFactorSources().filter(filter))
	}

	public func getFactorSources<Source: FactorSourceProtocol>(
		type _: Source.Type
	) async throws -> IdentifiedArrayOf<Source> {
		try await IdentifiedArrayOf(uniqueElements: getFactorSources().compactMap { $0.extract(Source.self) })
	}
}

// MARK: - UpdateFactorSourceLastUsedRequest
public struct UpdateFactorSourceLastUsedRequest: Sendable, Hashable {
	public let factorSourceIDs: [FactorSourceID]
	public let lastUsedOn: Date
	public let usagePurpose: SigningPurpose
	public init(
		factorSourceIDs: [FactorSourceID],
		usagePurpose: SigningPurpose,
		lastUsedOn: Date = .init()
	) {
		self.factorSourceIDs = factorSourceIDs
		self.usagePurpose = usagePurpose
		self.lastUsedOn = lastUsedOn
	}
}

// MARK: - SigningFactor
public struct SigningFactor: Sendable, Hashable, Identifiable {
	public typealias ID = FactorSourceID
	public var id: ID { factorSource.id }
	public let factorSource: FactorSource
	public typealias Signers = NonEmpty<IdentifiedArrayOf<Signer>>
	public var signers: Signers

	public var expectedSignatureCount: Int {
		signers.map(\.factorInstancesRequiredToSign.count).reduce(0, +)
	}

	public init(
		factorSource: FactorSource,
		signers: Signers
	) {
		self.factorSource = factorSource
		self.signers = signers
	}

	public init(
		factorSource: FactorSource,
		signer: Signer
	) {
		self.init(
			factorSource: factorSource,
			signers: .init(rawValue: .init(uniqueElements: [signer]))! // ok to force unwrap since we know we have one element.
		)
	}
}

extension FactorSourcesClient {
	public func addOffDeviceFactorSource(
		mnemonicWithPassphrase: MnemonicWithPassphrase,
		label: OffDeviceMnemonicFactorSource.Hint.Label
	) async throws -> FactorSource {
		let factorSource = try OffDeviceMnemonicFactorSource.from(
			mnemonicWithPassphrase: mnemonicWithPassphrase,
			label: label
		)

		_ = try await addPrivateHDFactorSource(.init(
			factorSource: factorSource.embed(),
			mnemonicWithPasshprase: mnemonicWithPassphrase,
			saveIntoProfile: true
		))

		return factorSource.embed()
	}

	public func addOnDeviceFactorSource(
		onDeviceMnemonicKind: MnemonicBasedFactorSourceKind.OnDeviceMnemonicKind,
		mnemonicWithPassphrase: MnemonicWithPassphrase,
		saveIntoProfile: Bool? = nil
	) async throws -> FactorSource {
		let isOlympiaCompatible = onDeviceMnemonicKind == .olympia
		let shouldSaveIntoProfile: Bool = saveIntoProfile ?? isOlympiaCompatible

		let factorSource: DeviceFactorSource = try isOlympiaCompatible
			? .olympia(mnemonicWithPassphrase: mnemonicWithPassphrase)
			: .babylon(mnemonicWithPassphrase: mnemonicWithPassphrase)

		_ = try await addPrivateHDFactorSource(.init(
			factorSource: factorSource.embed(),
			mnemonicWithPasshprase: mnemonicWithPassphrase,
			saveIntoProfile: shouldSaveIntoProfile
		))

		return factorSource.embed()
	}
}

// Move elsewhere?
import Cryptography
extension MnemonicWithPassphrase {
	@discardableResult
	public func validatePublicKeysOf(
		softwareAccounts: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>
	) throws -> Bool {
		try validatePublicKeysOf(
			accounts: softwareAccounts.map {
				(
					path: $0.path.fullPath,
					expectedPublicKey: .ecdsaSecp256k1($0.publicKey)
				)
			}
		)
	}

	@discardableResult
	public func validatePublicKeysOf(
		accounts: [Profile.Network.Account]
	) throws -> Bool {
		try validatePublicKeysOf(
			accounts: accounts.flatMap { account in
				try account.virtualHierarchicalDeterministicFactorInstances.map {
					try (
						path: $0.derivationPath.hdFullPath(),
						expectedPublicKey: $0.publicKey
					)
				}
			}
		)
	}

	@discardableResult
	public func validatePublicKeysOf(
		accounts: [(path: HD.Path.Full, expectedPublicKey: SLIP10.PublicKey)]
	) throws -> Bool {
		let hdRoot = try self.hdRoot()

		for account in accounts {
			let path = account.0
			let publicKey = account.1

			let derivedPublicKey: SLIP10.PublicKey = try {
				switch publicKey.curve {
				case .secp256k1:
					return try .ecdsaSecp256k1(hdRoot.derivePrivateKey(
						path: path,
						curve: SECP256K1.self
					).publicKey)
				case .curve25519:
					return try .eddsaEd25519(hdRoot.derivePrivateKey(
						path: path,
						curve: Curve25519.self
					).publicKey)
				}
			}()

			guard derivedPublicKey == publicKey else {
				throw ValidateMnemonicAgainstEntities.publicKeyMismatch
			}
		}
		// PublicKeys matches
		return true
	}
}

// MARK: - ValidateMnemonicAgainstEntities
enum ValidateMnemonicAgainstEntities: LocalizedError {
	case publicKeyMismatch
}
