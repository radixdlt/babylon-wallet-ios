import Sargon

// MARK: - FactorSourcesClient
struct FactorSourcesClient: Sendable {
	var indicesOfEntitiesControlledByFactorSource: IndicesOfEntitiesControlledByFactorSource
	var nextEntityIndexForFactorSource: NextEntityIndexForFactorSource
	var getCurrentNetworkID: GetCurrentNetworkID
	var getMainDeviceFactorSource: GetMainDeviceFactorSource
	var createNewMainDeviceFactorSource: CreateNewMainDeviceFactorSource
	var getFactorSources: GetFactorSources
	var factorSourcesAsyncSequence: FactorSourcesAsyncSequence
	var addPrivateHDFactorSource: AddPrivateHDFactorSource
	var checkIfHasOlympiaFactorSourceForAccounts: CheckIfHasOlympiaFactorSourceForAccounts
	var saveFactorSource: SaveFactorSource
	var updateFactorSource: UpdateFactorSource
	var getSigningFactors: GetSigningFactors
	var updateLastUsed: UpdateLastUsed
	var flagFactorSourceForDeletion: FlagFactorSourceForDeletion

	init(
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
struct NextEntityIndexForFactorSourceRequest {
	let entityKind: EntityKind

	/// `nil` means use main BDFS
	let factorSourceID: FactorSourceID?

	/// If DeviceFactorSource with mnemonic `M` is used to derive Account with CAP26 derivation path at index `0`, then we must
	/// allow `M` to be able to derive account wit hBIP44-like derivation path at index `0` as well in the future.
	let derivationPathScheme: DerivationPathScheme

	/// `nil` means `currentNetwork`
	let networkID: NetworkID?
}

// MARK: - IndicesOfEntitiesControlledByFactorSourceRequest
struct IndicesOfEntitiesControlledByFactorSourceRequest: Sendable, Hashable {
	let entityKind: EntityKind
	let factorSourceID: FactorSourceID

	/// If DeviceFactorSource with mnemonic `M` is used to derive Account with CAP26 derivation path at index `0`, then we must
	/// allow `M` to be able to derive account wit hBIP44-like derivation path at index `0` as well in the future.
	let derivationPathScheme: DerivationPathScheme

	let networkID: NetworkID?
}

// MARK: - IndicesUsedByFactorSource
struct IndicesUsedByFactorSource: Sendable, Hashable {
	let indices: OrderedSet<HdPathComponent>
	let factorSource: FactorSource
	let currentNetworkID: NetworkID
}

// MARK: FactorSourcesClient.GetFactorSources
extension FactorSourcesClient {
	typealias IndicesOfEntitiesControlledByFactorSource = @Sendable (IndicesOfEntitiesControlledByFactorSourceRequest) async throws -> IndicesUsedByFactorSource
	typealias NextEntityIndexForFactorSource = @Sendable (NextEntityIndexForFactorSourceRequest) async throws -> HdPathComponent
	typealias GetCurrentNetworkID = @Sendable () async -> NetworkID
	typealias GetMainDeviceFactorSource = @Sendable () async throws -> DeviceFactorSource
	typealias CreateNewMainDeviceFactorSource = @Sendable () async throws -> PrivateHierarchicalDeterministicFactorSource
	typealias GetFactorSources = @Sendable () async throws -> FactorSources
	typealias FactorSourcesAsyncSequence = @Sendable () async -> AnyAsyncSequence<FactorSources>
	typealias AddPrivateHDFactorSource = @Sendable (AddPrivateHDFactorSourceRequest) async throws -> FactorSourceIDFromHash
	typealias CheckIfHasOlympiaFactorSourceForAccounts = @Sendable (BIP39WordCount, NonEmpty<OrderedSet<OlympiaAccountToMigrate>>) async -> FactorSourceIDFromHash?
	typealias SaveFactorSource = @Sendable (FactorSource) async throws -> Void
	typealias UpdateFactorSource = @Sendable (FactorSource) async throws -> Void
	typealias GetSigningFactors = @Sendable (GetSigningFactorsRequest) async throws -> SigningFactors
	typealias UpdateLastUsed = @Sendable (UpdateFactorSourceLastUsedRequest) async throws -> Void
	typealias FlagFactorSourceForDeletion = @Sendable (FactorSourceID) async throws -> Void
}

// MARK: - AddPrivateHDFactorSourceRequest
struct AddPrivateHDFactorSourceRequest: Sendable, Hashable {
	let privateHDFactorSource: PrivateHierarchicalDeterministicFactorSource
	let onMnemonicExistsStrategy: ImportMnemonic.State.PersistStrategy.OnMnemonicExistsStrategy
	/// E.g. import babylon factor sources should only be saved keychain, not profile (already there).
	let saveIntoProfile: Bool
	init(
		privateHDFactorSource: PrivateHierarchicalDeterministicFactorSource,
		onMnemonicExistsStrategy: ImportMnemonic.State.PersistStrategy.OnMnemonicExistsStrategy,
		saveIntoProfile: Bool
	) {
		self.privateHDFactorSource = privateHDFactorSource
		self.saveIntoProfile = saveIntoProfile
		self.onMnemonicExistsStrategy = onMnemonicExistsStrategy
	}
}

typealias SigningFactors = OrderedDictionary<FactorSourceKind, NonEmpty<Set<SigningFactor>>>

extension SigningFactors {
	var expectedSignatureCount: Int {
		values.flatMap { $0.map(\.expectedSignatureCount) }.reduce(0, +)
	}
}

// MARK: - GetSigningFactorsRequest
struct GetSigningFactorsRequest: Sendable, Hashable {
	let networkID: NetworkID
	let signers: NonEmpty<Set<AccountOrPersona>>
	let signingPurpose: SigningPurpose
	init(networkID: NetworkID, signers: NonEmpty<Set<AccountOrPersona>>, signingPurpose: SigningPurpose) {
		self.networkID = networkID
		self.signers = signers
		self.signingPurpose = signingPurpose
	}
}

extension FactorSourcesClient {
	func createNewMainBDFS() async throws -> PrivateHierarchicalDeterministicFactorSource {
		try await createNewMainDeviceFactorSource()
	}

	func getFactorSource(
		id: FactorSourceID,
		matching filter: @escaping (FactorSource) -> Bool = { _ in true }
	) async throws -> FactorSource? {
		try await getFactorSources(matching: filter)[id: id]
	}

	func getDeviceFactorSource(
		of hdFactorInstance: HierarchicalDeterministicFactorInstance
	) async throws -> DeviceFactorSource? {
		guard let factorSource = try await getFactorSource(of: hdFactorInstance.factorInstance) else {
			return nil
		}
		return try factorSource.extract(as: DeviceFactorSource.self)
	}

	func getFactorSource<Source: FactorSourceProtocol>(
		id: FactorSourceID,
		as _: Source.Type
	) async throws -> Source? {
		try await getFactorSource(id: id)?.extract(Source.self)
	}

	func getFactorSource(
		of factorInstance: FactorInstance
	) async throws -> FactorSource? {
		try await getFactorSource(id: factorInstance.factorSourceID)
	}

	func getFactorSources(
		matching filter: (FactorSource) -> Bool
	) async throws -> IdentifiedArrayOf<FactorSource> {
		try await IdentifiedArrayOf(uniqueElements: getFactorSources().filter(filter))
	}

	func getFactorSources<Source: FactorSourceProtocol>(
		type _: Source.Type
	) async throws -> IdentifiedArrayOf<Source> {
		try await IdentifiedArrayOf(uniqueElements: getFactorSources().compactMap { $0.extract(Source.self) })
	}
}

// MARK: - UpdateFactorSourceLastUsedRequest
struct UpdateFactorSourceLastUsedRequest: Sendable, Hashable {
	let factorSourceIDs: [FactorSourceID]
	let lastUsedOn: Date
	let usagePurpose: SigningPurpose
	init(
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
struct SigningFactor: Sendable, Hashable, Identifiable {
	typealias ID = FactorSourceID
	var id: ID { factorSource.id }
	let factorSource: FactorSource
	typealias Signers = NonEmpty<IdentifiedArrayOf<Signer>>
	var signers: Signers

	var expectedSignatureCount: Int {
		signers.map(\.factorInstancesRequiredToSign.count).reduce(0, +)
	}

	init(
		factorSource: FactorSource,
		signers: Signers
	) {
		self.factorSource = factorSource
		self.signers = signers
	}

	init(
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
	func saveNewMainBDFS(_ newMainBDFS: DeviceFactorSource) async throws {
		let oldMainBDFSSources = try await getFactorSources(type: DeviceFactorSource.self).filter(\.isExplicitMainBDFS)

		for oldMainBDFS in oldMainBDFSSources {
			try await updateFactorSource(oldMainBDFS.removingMainFlag().asGeneral)
		}

		try await saveFactorSource(newMainBDFS.asGeneral)
	}

	@discardableResult
	func addOnDeviceFactorSource(
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

	func addOnDeviceFactorSource(
		onDeviceMnemonicKind: OnDeviceMnemonicKind,
		mnemonicWithPassphrase: MnemonicWithPassphrase,
		onMnemonicExistsStrategy: ImportMnemonic.State.PersistStrategy.OnMnemonicExistsStrategy,
		saveIntoProfile: Bool
	) async throws -> DeviceFactorSource {
		@Dependency(\.secureStorageClient) var secureStorageClient

		let hostInfo = await SargonOS.shared.resolveHostInfo()
		let factorSource = switch onDeviceMnemonicKind {
		case let .babylon(isMain):
			DeviceFactorSource.babylon(
				mnemonicWithPassphrase: mnemonicWithPassphrase,
				isMain: isMain,
				hostInfo: hostInfo
			)
		case .olympia:
			DeviceFactorSource.olympia(
				mnemonicWithPassphrase: mnemonicWithPassphrase,
				hostInfo: hostInfo
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

extension FactorSourcesClient {
	enum ShieldFactorStatus {
		/// A shield can be built from the available Factor Sources
		case valid

		/// At least one hardware Factor Source must be added in order to build a Shield.
		/// Note: this doesn't mean that after adding a hardware Factor Source we would have `valid` status.
		case hardwareRequired

		/// One more Factor Source, of any kind, must be added in order to build a Shield.
		case anyRequired
	}

	// TODO: Move to Sargon? Maybe we can get it from Alex's work
	func getShieldFactorStatus() async throws -> ShieldFactorStatus {
		let factorSources = try await getFactorSources()
		let totalCount = factorSources.count
		let hardwareCount = factorSources.filter(\.kind.isHardware).count
		if hardwareCount < 1 {
			return .hardwareRequired
		} else if totalCount < 2 {
			return .anyRequired
		} else {
			return .valid
		}
	}
}

// MARK: - OnDeviceMnemonicKind
enum OnDeviceMnemonicKind: Sendable, Hashable {
	case babylon(isMain: Bool)
	case olympia
}

private extension FactorSourceKind {
	// TODO: Move to Sargon?
	var isHardware: Bool {
		switch self {
		case .arculusCard, .ledgerHqHardwareWallet:
			true
		case .device, .offDeviceMnemonic, .trustedContact, .securityQuestions, .password:
			false
		}
	}
}
