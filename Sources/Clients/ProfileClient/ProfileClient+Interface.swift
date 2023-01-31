import ClientPrelude
import Cryptography

// MARK: - ProfileClient
public struct ProfileClient: Sendable {
	public var getCurrentNetworkID: GetCurrentNetworkID
	public var getGatewayAPIEndpointBaseURL: GetGatewayAPIEndpointBaseURL
	public var getNetworkAndGateway: GetNetworkAndGateway
	public var setNetworkAndGateway: SetNetworkAndGateway

	/// Creates a new profile without injecting it into the ProfileClient (ProfileHolder)
	public var createNewProfile: CreateNewProfile

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
	public var createUnsavedVirtualAccount: CreateUnsavedVirtualAccount
	public var createUnsavedVirtualPersona: CreateUnsavedVirtualPersona
	public var addAccount: AddAccount
	public var addPersona: AddPersona
	public var lookupAccountByAddress: LookupAccountByAddress

	public var signersForAccountsGivenAddresses: SignersForAccountsGivenAddresses

	public init(
		getCurrentNetworkID: @escaping GetCurrentNetworkID,
		getGatewayAPIEndpointBaseURL: @escaping GetGatewayAPIEndpointBaseURL,
		getNetworkAndGateway: @escaping GetNetworkAndGateway,
		setNetworkAndGateway: @escaping SetNetworkAndGateway,
		createNewProfile: @escaping CreateNewProfile,
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
		createUnsavedVirtualAccount: @escaping CreateUnsavedVirtualAccount,
		createUnsavedVirtualPersona: @escaping CreateUnsavedVirtualPersona,
		addAccount: @escaping AddAccount,
		addPersona: @escaping AddPersona,
		lookupAccountByAddress: @escaping LookupAccountByAddress,
		signersForAccountsGivenAddresses: @escaping SignersForAccountsGivenAddresses
	) {
		self.getCurrentNetworkID = getCurrentNetworkID
		self.getGatewayAPIEndpointBaseURL = getGatewayAPIEndpointBaseURL
		self.getNetworkAndGateway = getNetworkAndGateway
		self.setNetworkAndGateway = setNetworkAndGateway
		self.createNewProfile = createNewProfile
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
		self.createUnsavedVirtualAccount = createUnsavedVirtualAccount
		self.createUnsavedVirtualPersona = createUnsavedVirtualPersona
		self.addAccount = addAccount
		self.addPersona = addPersona
		self.lookupAccountByAddress = lookupAccountByAddress
		self.signersForAccountsGivenAddresses = signersForAccountsGivenAddresses
	}
}

public extension ProfileClient {
	typealias LoadProfileResult = Swift.Result<Profile?, Profile.LoadingFailure>
	typealias LoadProfile = @Sendable () async -> LoadProfileResult

	typealias GetGatewayAPIEndpointBaseURL = @Sendable () async -> URL
	typealias GetCurrentNetworkID = @Sendable () async -> NetworkID

	typealias SetNetworkAndGateway = @Sendable (AppPreferences.NetworkAndGateway) async throws -> Void

	typealias GetNetworkAndGateway = @Sendable () async -> AppPreferences.NetworkAndGateway

	// Returns the first account on the current Network for this new Profile. Which is what the `CreateAccount` feature uses (used during Onboarding).
	typealias CreateNewProfile = @Sendable (CreateNewProfileRequest) async throws -> OnNetwork.Account

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
	typealias CreateUnsavedVirtualAccount = @Sendable (CreateAccountRequest) async throws -> OnNetwork.Account
	typealias CreateUnsavedVirtualPersona = @Sendable (CreatePersonaRequest) async throws -> OnNetwork.Persona
	typealias AddAccount = @Sendable (OnNetwork.Account) async throws -> Void
	typealias AddPersona = @Sendable (OnNetwork.Persona) async throws -> Void
	typealias LookupAccountByAddress = @Sendable (AccountAddress) async throws -> OnNetwork.Account

	typealias SignersForAccountsGivenAddresses = @Sendable (SignersForAccountsGivenAddressesRequest) async throws -> NonEmpty<OrderedSet<SignersOfAccount>>
}

public typealias SignersOfAccount = SignersOf<OnNetwork.Account>
