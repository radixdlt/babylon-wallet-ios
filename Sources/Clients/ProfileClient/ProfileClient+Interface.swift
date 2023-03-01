import ClientPrelude
import Cryptography

// MARK: - ProfileClient
public struct ProfileClient: Sendable {
	// MARK: - =====

	// MARK: - =====

	// MARK: - =====

	struct Separator {}

	// MARK: - Migrated

	// To: FactorSourceClient
	public var getFactorSources: GetFactorSources

	// To: OnboardingClient
	public var createEphemeralPrivateProfile: CreateEphemeralPrivateProfile
	public var injectProfileSnapshot: InjectProfileSnapshot
	public var commitEphemeralPrivateProfile: CommitEphemeralPrivateProfile
	public var loadProfile: LoadProfile

	// To: AccountsClient
	public var getAccounts: GetAccounts
	public var addAccount: AddAccount
	public var lookupAccountByAddress: LookupAccountByAddress
	public var hasAccountOnNetwork: HasAccountOnNetwork
	public var getAccountsOnNetwork: GetAccountsOnNetwork

	// To: PersonasClient
	public var getPersonas: GetPersonas
	public var addPersona: AddPersona

	// To: AuthorizedDappsClient

	// MARK: - Not Yet Migrated
	public var getCurrentNetworkID: GetCurrentNetworkID
	public var getGatewayAPIEndpointBaseURL: GetGatewayAPIEndpointBaseURL
	public var getGateways: GetGateways
	public var setGateway: SetGateway

	public var extractProfileSnapshot: ExtractProfileSnapshot
	public var deleteProfileAndFactorSources: DeleteProfileSnapshot

	public var getP2PClients: GetP2PClients
	public var getAuthorizedDapps: GetAuthorizedDapps
	public var addAuthorizedDapp: AddAuthorizedDapp
	public var forgetAuthorizedDapp: ForgetAuthorizedDapp
	public var addP2PClient: AddP2PClient
	public var updateAuthorizedDapp: UpdateAuthorizedDapp
	public var disconnectPersonaFromDapp: DisconnectPersonaFromDapp
	public var detailsForAuthorizedDapp: DetailsForAuthorizedDapp
	public var deleteP2PClientByID: DeleteP2PClientByID
	public var getAppPreferences: GetAppPreferences
	public var setDisplayAppPreferences: SetDisplayAppPreferences
	public var createUnsavedVirtualEntity: CreateUnsavedVirtualEntity

	public init(
		getFactorSources: @escaping GetFactorSources,
		getCurrentNetworkID: @escaping GetCurrentNetworkID,
		getGatewayAPIEndpointBaseURL: @escaping GetGatewayAPIEndpointBaseURL,
		getGateways: @escaping GetGateways,
		setGateway: @escaping SetGateway,
		createEphemeralPrivateProfile: @escaping CreateEphemeralPrivateProfile,
		injectProfileSnapshot: @escaping InjectProfileSnapshot,
		commitEphemeralPrivateProfile: @escaping CommitEphemeralPrivateProfile,
		loadProfile: @escaping LoadProfile,
		extractProfileSnapshot: @escaping ExtractProfileSnapshot,
		deleteProfileAndFactorSources: @escaping DeleteProfileSnapshot,
		hasAccountOnNetwork: @escaping HasAccountOnNetwork,
		getAccountsOnNetwork: @escaping GetAccountsOnNetwork,
		getAccounts: @escaping GetAccounts,
		getPersonas: @escaping GetPersonas,
		getP2PClients: @escaping GetP2PClients,
		getAuthorizedDapps: @escaping GetAuthorizedDapps,
		addAuthorizedDapp: @escaping AddAuthorizedDapp,
		forgetAuthorizedDapp: @escaping ForgetAuthorizedDapp,
		detailsForAuthorizedDapp: @escaping DetailsForAuthorizedDapp,
		updateAuthorizedDapp: @escaping UpdateAuthorizedDapp,
		disconnectPersonaFromDapp: @escaping DisconnectPersonaFromDapp,
		addP2PClient: @escaping AddP2PClient,
		deleteP2PClientByID: @escaping DeleteP2PClientByID,
		getAppPreferences: @escaping GetAppPreferences,
		setDisplayAppPreferences: @escaping SetDisplayAppPreferences,
		createUnsavedVirtualEntity: @escaping CreateUnsavedVirtualEntity,
		addAccount: @escaping AddAccount,
		addPersona: @escaping AddPersona,
		lookupAccountByAddress: @escaping LookupAccountByAddress
	) {
		self.getFactorSources = getFactorSources
		self.getCurrentNetworkID = getCurrentNetworkID
		self.getGatewayAPIEndpointBaseURL = getGatewayAPIEndpointBaseURL
		self.getGateways = getGateways
		self.setGateway = setGateway
		self.createEphemeralPrivateProfile = createEphemeralPrivateProfile
		self.commitEphemeralPrivateProfile = commitEphemeralPrivateProfile
		self.injectProfileSnapshot = injectProfileSnapshot
		self.loadProfile = loadProfile
		self.extractProfileSnapshot = extractProfileSnapshot
		self.deleteProfileAndFactorSources = deleteProfileAndFactorSources
		self.hasAccountOnNetwork = hasAccountOnNetwork
		self.getAccountsOnNetwork = getAccountsOnNetwork
		self.getAccounts = getAccounts
		self.getPersonas = getPersonas
		self.getAuthorizedDapps = getAuthorizedDapps
		self.addAuthorizedDapp = addAuthorizedDapp
		self.forgetAuthorizedDapp = forgetAuthorizedDapp
		self.detailsForAuthorizedDapp = detailsForAuthorizedDapp
		self.updateAuthorizedDapp = updateAuthorizedDapp
		self.disconnectPersonaFromDapp = disconnectPersonaFromDapp
		self.getP2PClients = getP2PClients
		self.addP2PClient = addP2PClient
		self.deleteP2PClientByID = deleteP2PClientByID
		self.getAppPreferences = getAppPreferences
		self.setDisplayAppPreferences = setDisplayAppPreferences
		self.createUnsavedVirtualEntity = createUnsavedVirtualEntity
		self.addAccount = addAccount
		self.addPersona = addPersona
		self.lookupAccountByAddress = lookupAccountByAddress
	}
}

// MARK: - CreateEphemeralPrivateProfileRequest
public struct CreateEphemeralPrivateProfileRequest: Sendable, Hashable {
	public let language: BIP39.Language
	public let wordCount: BIP39.WordCount
	public let bip39Passphrase: String

	public init(
		language: BIP39.Language = .english,
		wordCount: BIP39.WordCount = .twentyFour,
		bip39Passphrase: String = ""
	) {
		self.language = language
		self.wordCount = wordCount
		self.bip39Passphrase = bip39Passphrase
	}
}

extension ProfileClient {
	public typealias GetDerivationPathForNewEntity = @Sendable (GetDerivationPathForNewEntityRequest) async throws -> (path: DerivationPath, index: Int)

	public typealias GetFactorSources = @Sendable () async throws -> FactorSources
	public typealias LoadProfileResult = Swift.Result<Profile?, Profile.LoadingFailure>
	public typealias LoadProfile = @Sendable () async -> LoadProfileResult

	public typealias GetGatewayAPIEndpointBaseURL = @Sendable () async -> URL
	public typealias GetCurrentNetworkID = @Sendable () async -> NetworkID

	public typealias SetGateway = @Sendable (Gateway) async throws -> Void

	public typealias GetGateways = @Sendable () async -> Gateways

	public typealias CreateEphemeralPrivateProfile = @Sendable (CreateEphemeralPrivateProfileRequest) async throws -> Profile.Ephemeral.Private

	public typealias InjectProfileSnapshot = @Sendable (ProfileSnapshot) async throws -> Void
	public typealias CommitEphemeralPrivateProfile = @Sendable (Profile.Ephemeral.Private) async throws -> Void

	public typealias DeleteProfileSnapshot = @Sendable () async throws -> Void

	// ALL METHOD MUST BE THROWING! SINCE IF A PROFILE HAS NOT BEEN INJECTED WE SHOULD THROW AN ERROR
	public typealias ExtractProfileSnapshot = @Sendable () async throws -> ProfileSnapshot
	public typealias HasAccountOnNetwork = @Sendable (NetworkID) async throws -> Bool
	public typealias GetAccountsOnNetwork = @Sendable (NetworkID) async throws -> NonEmpty<IdentifiedArrayOf<OnNetwork.Account>>
	public typealias GetAccounts = @Sendable () async throws -> NonEmpty<IdentifiedArrayOf<OnNetwork.Account>>
	public typealias GetPersonas = @Sendable () async throws -> IdentifiedArrayOf<OnNetwork.Persona>
	public typealias GetAuthorizedDapps = @Sendable () async throws -> IdentifiedArrayOf<OnNetwork.AuthorizedDapp>
	public typealias DetailsForAuthorizedDapp = @Sendable (OnNetwork.AuthorizedDapp) async throws -> OnNetwork.AuthorizedDappDetailed
	public typealias GetP2PClients = @Sendable () async throws -> P2PClients
	public typealias AddP2PClient = @Sendable (P2PClient) async throws -> Void
	public typealias AddAuthorizedDapp = @Sendable (OnNetwork.AuthorizedDapp) async throws -> Void
	public typealias ForgetAuthorizedDapp = @Sendable (OnNetwork.AuthorizedDapp.ID, NetworkID) async throws -> Void
	public typealias UpdateAuthorizedDapp = @Sendable (OnNetwork.AuthorizedDapp) async throws -> Void
	public typealias DisconnectPersonaFromDapp = @Sendable (OnNetwork.Persona.ID, OnNetwork.AuthorizedDapp.ID, NetworkID) async throws -> Void
	public typealias DeleteP2PClientByID = @Sendable (P2PClient.ID) async throws -> Void
	public typealias GetAppPreferences = @Sendable () async throws -> AppPreferences
	public typealias SetDisplayAppPreferences = @Sendable (AppPreferences.Display) async throws -> Void
	public typealias CreateUnsavedVirtualEntity = @Sendable (CreateVirtualEntityRequest) async throws -> any EntityProtocol
	public typealias AddAccount = @Sendable (OnNetwork.Account) async throws -> Void
	public typealias AddPersona = @Sendable (OnNetwork.Persona) async throws -> Void
	public typealias LookupAccountByAddress = @Sendable (AccountAddress) async throws -> OnNetwork.Account
}

extension ProfileClient {
	public func getDetailedDapp(_ id: OnNetwork.AuthorizedDapp.ID) async throws -> OnNetwork.AuthorizedDappDetailed {
		let dApps = try await getAuthorizedDapps()
		guard let dApp = dApps[id: id] else {
			throw AuthorizedDappDoesNotExists()
		}
		return try await detailsForAuthorizedDapp(dApp)
	}
}

// MARK: - AuthorizedDappDoesNotExists
struct AuthorizedDappDoesNotExists: Swift.Error {}
