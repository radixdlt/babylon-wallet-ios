import Sargon

// MARK: - FactorSourcesClient
public struct FactorSourcesClient: Sendable {
	public var indicesOfEntitiesControlledByFactorSource: IndicesOfEntitiesControlledByFactorSource
	public var nextEntityIndexForFactorSource: NextEntityIndexForFactorSource
	public var getCurrentNetworkID: GetCurrentNetworkID
	public var getMainDeviceFactorSource: GetMainDeviceFactorSource
	public var createNewMainDeviceFactorSource: CreateNewMainDeviceFactorSource
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
		indicesOfEntitiesControlledByFactorSource: @escaping IndicesOfEntitiesControlledByFactorSource,
		getCurrentNetworkID: @escaping GetCurrentNetworkID,
		getMainDeviceFactorSource: @escaping GetMainDeviceFactorSource,
		createNewMainDeviceFactorSource: @escaping CreateNewMainDeviceFactorSource,
		getFactorSources: @escaping GetFactorSources,
		factorSourcesAsyncSequence: @escaping FactorSourcesAsyncSequence,
		nextEntityIndexForFactorSource: @escaping NextEntityIndexForFactorSource,
		addPrivateHDFactorSource: @escaping AddPrivateHDFactorSource,
		checkIfHasOlympiaFactorSourceForAccounts: @escaping CheckIfHasOlympiaFactorSourceForAccounts,
		saveFactorSource: @escaping SaveFactorSource,
		updateFactorSource: @escaping UpdateFactorSource,
		getSigningFactors: @escaping GetSigningFactors,
		updateLastUsed: @escaping UpdateLastUsed,
		flagFactorSourceForDeletion: @escaping FlagFactorSourceForDeletion
	) {
		self.indicesOfEntitiesControlledByFactorSource = indicesOfEntitiesControlledByFactorSource
		self.getCurrentNetworkID = getCurrentNetworkID
		self.getMainDeviceFactorSource = getMainDeviceFactorSource
		self.createNewMainDeviceFactorSource = createNewMainDeviceFactorSource
		self.getFactorSources = getFactorSources
		self.factorSourcesAsyncSequence = factorSourcesAsyncSequence
		self.nextEntityIndexForFactorSource = nextEntityIndexForFactorSource
		self.addPrivateHDFactorSource = addPrivateHDFactorSource
		self.checkIfHasOlympiaFactorSourceForAccounts = checkIfHasOlympiaFactorSourceForAccounts
		self.saveFactorSource = saveFactorSource
		self.updateFactorSource = updateFactorSource
		self.getSigningFactors = getSigningFactors
		self.updateLastUsed = updateLastUsed
		self.flagFactorSourceForDeletion = flagFactorSourceForDeletion
	}
}

// MARK: - NextEntityIndexForFactorSourceRequest
public struct NextEntityIndexForFactorSourceRequest {
	public let entityKind: EntityKind

	/// `nil` means use main BDFS
	public let factorSourceID: FactorSourceID?

	/// If DeviceFactorSource with mnemonic `M` is used to derive Account with CAP26 derivation path at index `0`, then we must
	/// allow `M` to be able to derive account wit hBIP44-like derivation path at index `0` as well in the future.
	public let derivationPathScheme: DerivationPathScheme

	/// `nil` means `currentNetwork`
	public let networkID: NetworkID?
}

// MARK: - IndicesOfEntitiesControlledByFactorSourceRequest
public struct IndicesOfEntitiesControlledByFactorSourceRequest: Sendable, Hashable {
	public let entityKind: EntityKind
	public let factorSourceID: FactorSourceID

	/// If DeviceFactorSource with mnemonic `M` is used to derive Account with CAP26 derivation path at index `0`, then we must
	/// allow `M` to be able to derive account wit hBIP44-like derivation path at index `0` as well in the future.
	public let derivationPathScheme: DerivationPathScheme

	public let networkID: NetworkID?
}

// MARK: - IndicesUsedByFactorSource
public struct IndicesUsedByFactorSource: Sendable, Hashable {
	let indices: OrderedSet<HDPathValue>
	let factorSource: FactorSource
	let currentNetworkID: NetworkID
}

// MARK: FactorSourcesClient.GetFactorSources
extension FactorSourcesClient {
	public typealias IndicesOfEntitiesControlledByFactorSource = @Sendable (IndicesOfEntitiesControlledByFactorSourceRequest) async throws -> IndicesUsedByFactorSource
	public typealias NextEntityIndexForFactorSource = @Sendable (NextEntityIndexForFactorSourceRequest) async throws -> HDPathValue
	public typealias GetCurrentNetworkID = @Sendable () async -> NetworkID
	public typealias GetMainDeviceFactorSource = @Sendable () async throws -> DeviceFactorSource
	public typealias CreateNewMainDeviceFactorSource = @Sendable () async throws -> PrivateHierarchicalDeterministicFactorSource
	public typealias GetFactorSources = @Sendable () async throws -> FactorSources
	public typealias FactorSourcesAsyncSequence = @Sendable () async -> AnyAsyncSequence<FactorSources>
	public typealias AddPrivateHDFactorSource = @Sendable (AddPrivateHDFactorSourceRequest) async throws -> FactorSourceIDFromHash
	public typealias CheckIfHasOlympiaFactorSourceForAccounts = @Sendable (BIP39WordCount, NonEmpty<OrderedSet<OlympiaAccountToMigrate>>) async -> FactorSourceIDFromHash?
	public typealias SaveFactorSource = @Sendable (FactorSource) async throws -> Void
	public typealias UpdateFactorSource = @Sendable (FactorSource) async throws -> Void
	public typealias GetSigningFactors = @Sendable (GetSigningFactorsRequest) async throws -> SigningFactors
	public typealias UpdateLastUsed = @Sendable (UpdateFactorSourceLastUsedRequest) async throws -> Void
	public typealias FlagFactorSourceForDeletion = @Sendable (FactorSourceID) async throws -> Void
}

// MARK: - AddPrivateHDFactorSourceRequest
public struct AddPrivateHDFactorSourceRequest: Sendable, Hashable {
	public let privateHDFactorSource: PrivateHierarchicalDeterministicFactorSource
	public let onMnemonicExistsStrategy: ImportMnemonic.State.PersistStrategy.OnMnemonicExistsStrategy
	/// E.g. import babylon factor sources should only be saved keychain, not profile (already there).
	public let saveIntoProfile: Bool
	public init(
		privateHDFactorSource: PrivateHierarchicalDeterministicFactorSource,
		onMnemonicExistsStrategy: ImportMnemonic.State.PersistStrategy.OnMnemonicExistsStrategy,
		saveIntoProfile: Bool
	) {
		self.privateHDFactorSource = privateHDFactorSource
		self.saveIntoProfile = saveIntoProfile
		self.onMnemonicExistsStrategy = onMnemonicExistsStrategy
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
	public let signers: NonEmpty<Set<AccountOrPersona>>
	public let signingPurpose: SigningPurpose
	public init(networkID: NetworkID, signers: NonEmpty<Set<AccountOrPersona>>, signingPurpose: SigningPurpose) {
		self.networkID = networkID
		self.signers = signers
		self.signingPurpose = signingPurpose
	}
}

extension FactorSourcesClient {
	public func createNewMainBDFS() async throws -> PrivateHierarchicalDeterministicFactorSource {
		try await createNewMainDeviceFactorSource()
	}

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
			signers: .init(rawValue: [signer].asIdentified())! // ok to force unwrap since we know we have one element.
		)
	}
}

extension FactorSourcesClient {
	public func saveNewMainBDFS(_ newMainBDFS: DeviceFactorSource) async throws {
		let oldMainBDFSSources = try await getFactorSources(type: DeviceFactorSource.self).filter(\.isExplicitMainBDFS)

		for oldMainBDFS in oldMainBDFSSources {
			try await updateFactorSource(oldMainBDFS.removingMainFlag().asGeneral)
		}

		try await saveFactorSource(newMainBDFS.asGeneral)
	}

	@discardableResult
	public func addOnDeviceFactorSource(
		privateHDFactorSource: PrivateHierarchicalDeterministicFactorSource,
		onMnemonicExistsStrategy: ImportMnemonic.State.PersistStrategy.OnMnemonicExistsStrategy,
		saveIntoProfile: Bool
	) async throws -> FactorSourceID {
		try await addPrivateHDFactorSource(
			.init(
				privateHDFactorSource: privateHDFactorSource,
				onMnemonicExistsStrategy: onMnemonicExistsStrategy,
				saveIntoProfile: saveIntoProfile
			)
		).asGeneral
	}

	public func addOnDeviceFactorSource(
		onDeviceMnemonicKind: OnDeviceMnemonicKind,
		mnemonicWithPassphrase: MnemonicWithPassphrase,
		onMnemonicExistsStrategy: ImportMnemonic.State.PersistStrategy.OnMnemonicExistsStrategy,
		saveIntoProfile: Bool
	) async throws -> DeviceFactorSource {
		@Dependency(\.secureStorageClient) var secureStorageClient

		let deviceInfo = secureStorageClient.loadDeviceInfoOrFallback()
		let factorSource = switch onDeviceMnemonicKind {
		case let .babylon(isMain):
			DeviceFactorSource.babylon(
				mnemonicWithPassphrase: mnemonicWithPassphrase,
				isMain: isMain,
				deviceInfo: deviceInfo
			)
		case .olympia:
			DeviceFactorSource.olympia(
				mnemonicWithPassphrase: mnemonicWithPassphrase,
				deviceInfo: deviceInfo
			)
		}

		try await self.addOnDeviceFactorSource(
			privateHDFactorSource: .init(
				mnemonicWithPassphrase: mnemonicWithPassphrase,
				factorSource: factorSource
			),
			onMnemonicExistsStrategy: onMnemonicExistsStrategy,
			saveIntoProfile: saveIntoProfile
		)

		return factorSource
	}
}

// MARK: - OnDeviceMnemonicKind
public enum OnDeviceMnemonicKind: Sendable, Hashable {
	case babylon(isMain: Bool)
	case olympia
}
