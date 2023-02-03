import ClientPrelude
import Cryptography

// MARK: - ProfileClient
public struct ProfileClient: Sendable {
	public var getFactorSources: GetFactorSources
	public var getCurrentNetworkID: GetCurrentNetworkID
	public var getGatewayAPIEndpointBaseURL: GetGatewayAPIEndpointBaseURL
	public var getNetworkAndGateway: GetNetworkAndGateway
	public var setNetworkAndGateway: SetNetworkAndGateway

	/// Creates a new profile without injecting it into the ProfileClient (ProfileHolder)
	public var createEphemeralProfileAndUnsavedOnDeviceFactorSource: CreateEphemeralProfileAndUnsavedOnDeviceFactorSource
	public var injectProfileSnapshot: InjectProfileSnapshot
	public var commitEphemeralProfileAndPersistOnDeviceFactorSourceMnemonic: CommitEphemeralProfileAndPersistOnDeviceFactorSourceMnemonic

	public var loadProfile: LoadProfile
	public var extractProfileSnapshot: ExtractProfileSnapshot

	/// Also deletes profile and factor sources from keychain
	public var deleteProfileAndFactorSources: DeleteProfileSnapshot

	public var hasAccountOnNetwork: HasAccountOnNetwork
	public var getAccounts: GetAccounts
	public var getPersonas: GetPersonas
	public var getP2PClients: GetP2PClients
	public var getConnectedDapps: GetConnectedDapps
	public var addConnectedDapp: AddConnectedDapp
	public var addP2PClient: AddP2PClient
	public var updateConnectedDapp: UpdateConnectedDapp
	public var detailsForConnectedDapp: DetailsForConnectedDapp
	public var deleteP2PClientByID: DeleteP2PClientByID
	public var getAppPreferences: GetAppPreferences
	public var setDisplayAppPreferences: SetDisplayAppPreferences
	public var createUnsavedVirtualEntity: CreateUnsavedVirtualEntity
	public var addAccount: AddAccount
	public var addPersona: AddPersona
	public var lookupAccountByAddress: LookupAccountByAddress

	public var signersForAccountsGivenAddresses: SignersForAccountsGivenAddresses

	public init(
		getFactorSources: @escaping GetFactorSources,
		getCurrentNetworkID: @escaping GetCurrentNetworkID,
		getGatewayAPIEndpointBaseURL: @escaping GetGatewayAPIEndpointBaseURL,
		getNetworkAndGateway: @escaping GetNetworkAndGateway,
		setNetworkAndGateway: @escaping SetNetworkAndGateway,
		createEphemeralProfileAndUnsavedOnDeviceFactorSource: @escaping CreateEphemeralProfileAndUnsavedOnDeviceFactorSource,
		injectProfileSnapshot: @escaping InjectProfileSnapshot,
		commitEphemeralProfileAndPersistOnDeviceFactorSourceMnemonic: @escaping CommitEphemeralProfileAndPersistOnDeviceFactorSourceMnemonic,
		loadProfile: @escaping LoadProfile,
		extractProfileSnapshot: @escaping ExtractProfileSnapshot,
		deleteProfileAndFactorSources: @escaping DeleteProfileSnapshot,
		hasAccountOnNetwork: @escaping HasAccountOnNetwork,
		getAccounts: @escaping GetAccounts,
		getPersonas: @escaping GetPersonas,
		getP2PClients: @escaping GetP2PClients,
		getConnectedDapps: @escaping GetConnectedDapps,
		addConnectedDapp: @escaping AddConnectedDapp,
		detailsForConnectedDapp: @escaping DetailsForConnectedDapp,
		updateConnectedDapp: @escaping UpdateConnectedDapp,
		addP2PClient: @escaping AddP2PClient,
		deleteP2PClientByID: @escaping DeleteP2PClientByID,
		getAppPreferences: @escaping GetAppPreferences,
		setDisplayAppPreferences: @escaping SetDisplayAppPreferences,
		createUnsavedVirtualEntity: @escaping CreateUnsavedVirtualEntity,
		addAccount: @escaping AddAccount,
		addPersona: @escaping AddPersona,
		lookupAccountByAddress: @escaping LookupAccountByAddress,
		signersForAccountsGivenAddresses: @escaping SignersForAccountsGivenAddresses
	) {
		self.getFactorSources = getFactorSources
		self.getCurrentNetworkID = getCurrentNetworkID
		self.getGatewayAPIEndpointBaseURL = getGatewayAPIEndpointBaseURL
		self.getNetworkAndGateway = getNetworkAndGateway
		self.setNetworkAndGateway = setNetworkAndGateway
		self.createEphemeralProfileAndUnsavedOnDeviceFactorSource = createEphemeralProfileAndUnsavedOnDeviceFactorSource
		self.commitEphemeralProfileAndPersistOnDeviceFactorSourceMnemonic = commitEphemeralProfileAndPersistOnDeviceFactorSourceMnemonic
		self.injectProfileSnapshot = injectProfileSnapshot
		self.loadProfile = loadProfile
		self.extractProfileSnapshot = extractProfileSnapshot
		self.deleteProfileAndFactorSources = deleteProfileAndFactorSources
		self.hasAccountOnNetwork = hasAccountOnNetwork
		self.getAccounts = getAccounts
		self.getPersonas = getPersonas
		self.getConnectedDapps = getConnectedDapps
		self.addConnectedDapp = addConnectedDapp
		self.detailsForConnectedDapp = detailsForConnectedDapp
		self.updateConnectedDapp = updateConnectedDapp
		self.getP2PClients = getP2PClients
		self.addP2PClient = addP2PClient
		self.deleteP2PClientByID = deleteP2PClientByID
		self.getAppPreferences = getAppPreferences
		self.setDisplayAppPreferences = setDisplayAppPreferences
		self.createUnsavedVirtualEntity = createUnsavedVirtualEntity
		self.addAccount = addAccount
		self.addPersona = addPersona
		self.lookupAccountByAddress = lookupAccountByAddress
		self.signersForAccountsGivenAddresses = signersForAccountsGivenAddresses
	}
}

// MARK: - CreateEphemeralProfileAndUnsavedOnDeviceFactorSourceRequest
public struct CreateEphemeralProfileAndUnsavedOnDeviceFactorSourceRequest: Sendable, Equatable {
	public let networkAndGateway: AppPreferences.NetworkAndGateway
	public let language: BIP39.Language
	public let wordCount: BIP39.WordCount
	public let bip39Passphrase: String
	public init(
		networkAndGateway: AppPreferences.NetworkAndGateway = .nebunet,
		language: BIP39.Language = .english,
		wordCount: BIP39.WordCount = .twentyFour,
		bip39Passphrase: String = ""
	) {
		self.networkAndGateway = networkAndGateway
		self.language = language
		self.wordCount = wordCount
		self.bip39Passphrase = bip39Passphrase
	}
}

// MARK: - CreateEphemeralProfileAndUnsavedOnDeviceFactorSourceResponse
public struct CreateEphemeralProfileAndUnsavedOnDeviceFactorSourceResponse: Sendable, Equatable {
	public let request: CreateEphemeralProfileAndUnsavedOnDeviceFactorSourceRequest
	public let onDeviceFactorSourceMnemonic: Mnemonic
	public let profile: Profile
	public init(
		request: CreateEphemeralProfileAndUnsavedOnDeviceFactorSourceRequest,
		mnemonic: Mnemonic,
		profile: Profile
	) {
		self.onDeviceFactorSourceMnemonic = mnemonic
		self.profile = profile
		self.request = request
	}
}

// MARK: - CommitEphemeralProfileAndPersistOnDeviceFactorSourceMnemonicRequest
public struct CommitEphemeralProfileAndPersistOnDeviceFactorSourceMnemonicRequest: Sendable, Equatable {
	public let onDeviceFactorSourceMnemonic: Mnemonic
	public let bip39Passphrase: String
	public init(onDeviceFactorSourceMnemonic: Mnemonic, bip39Passphrase: String) {
		self.onDeviceFactorSourceMnemonic = onDeviceFactorSourceMnemonic
		self.bip39Passphrase = bip39Passphrase
	}
}

public extension ProfileClient {
	typealias GetDerivationPathForNewEntity = @Sendable (GetDerivationPathForNewEntityRequest) async throws -> (path: DerivationPath, index: Int)

	typealias GetFactorSources = @Sendable () async throws -> FactorSources
	typealias LoadProfileResult = Swift.Result<Profile?, Profile.LoadingFailure>
	typealias LoadProfile = @Sendable () async -> LoadProfileResult

	typealias GetGatewayAPIEndpointBaseURL = @Sendable () async -> URL
	typealias GetCurrentNetworkID = @Sendable () async -> NetworkID

	typealias SetNetworkAndGateway = @Sendable (AppPreferences.NetworkAndGateway) async throws -> Void

	typealias GetNetworkAndGateway = @Sendable () async -> AppPreferences.NetworkAndGateway

	typealias CreateEphemeralProfileAndUnsavedOnDeviceFactorSource = @Sendable (CreateEphemeralProfileAndUnsavedOnDeviceFactorSourceRequest) async throws -> CreateEphemeralProfileAndUnsavedOnDeviceFactorSourceResponse

	typealias InjectProfileSnapshot = @Sendable (ProfileSnapshot) async throws -> Void
	typealias CommitEphemeralProfileAndPersistOnDeviceFactorSourceMnemonic = @Sendable (CommitEphemeralProfileAndPersistOnDeviceFactorSourceMnemonicRequest) async throws -> Void

	typealias DeleteProfileSnapshot = @Sendable () async throws -> Void

	// ALL METHOD MUST BE THROWING! SINCE IF A PROFILE HAS NOT BEEN INJECTED WE SHOULD THROW AN ERROR
	typealias ExtractProfileSnapshot = @Sendable () async throws -> ProfileSnapshot
	typealias HasAccountOnNetwork = @Sendable (NetworkID) async throws -> Bool
	typealias GetAccounts = @Sendable () async throws -> NonEmpty<IdentifiedArrayOf<OnNetwork.Account>>
	typealias GetPersonas = @Sendable () async throws -> IdentifiedArrayOf<OnNetwork.Persona>
	typealias GetConnectedDapps = @Sendable () async throws -> IdentifiedArrayOf<OnNetwork.ConnectedDapp>
	typealias DetailsForConnectedDapp = @Sendable (OnNetwork.ConnectedDapp) async throws -> OnNetwork.ConnectedDappDetailed
	typealias GetP2PClients = @Sendable () async throws -> P2PClients
	typealias AddP2PClient = @Sendable (P2PClient) async throws -> Void
	typealias AddConnectedDapp = @Sendable (OnNetwork.ConnectedDapp) async throws -> Void
	typealias UpdateConnectedDapp = @Sendable (OnNetwork.ConnectedDapp) async throws -> Void
	typealias DeleteP2PClientByID = @Sendable (P2PClient.ID) async throws -> Void
	typealias GetAppPreferences = @Sendable () async throws -> AppPreferences
	typealias SetDisplayAppPreferences = @Sendable (AppPreferences.Display) async throws -> Void
	typealias CreateUnsavedVirtualEntity = @Sendable (CreateVirtualEntityRequest) async throws -> any EntityProtocol
	typealias AddAccount = @Sendable (OnNetwork.Account) async throws -> Void
	typealias AddPersona = @Sendable (OnNetwork.Persona) async throws -> Void
	typealias LookupAccountByAddress = @Sendable (AccountAddress) async throws -> OnNetwork.Account

	typealias SignersForAccountsGivenAddresses = @Sendable (SignersForAccountsGivenAddressesRequest) async throws -> NonEmpty<OrderedSet<SignersOfAccount>>
}

public typealias SignersOfAccount = SignersOf<OnNetwork.Account>
