import ClientPrelude
import Cryptography
import Profile

extension DependencyValues {
	public var profileClient: ProfileClient {
		get { self[ProfileClient.self] }
		set { self[ProfileClient.self] = newValue }
	}
}

extension ProfileClient {
	public static let testValue = Self(
		getFactorSources: unimplemented("\(Self.self).getFactorSources"),
		getCurrentNetworkID: unimplemented("\(Self.self).getCurrentNetworkID"),
		getGatewayAPIEndpointBaseURL: unimplemented("\(Self.self).getGatewayAPIEndpointBaseURL"),
		getGateways: unimplemented("\(Self.self).getGateways"),
		setGateway: unimplemented("\(Self.self).setGateway"),
		createEphemeralPrivateProfile: unimplemented("\(Self.self).createEphemeralPrivateProfile"),
		injectProfileSnapshot: unimplemented("\(Self.self).injectProfileSnapshot"),
		commitEphemeralPrivateProfile: unimplemented("\(Self.self).commitEphemeralPrivateProfile"),
		loadProfile: unimplemented("\(Self.self).loadProfile"),
		extractProfileSnapshot: unimplemented("\(Self.self).extractProfileSnapshot"),
		deleteProfileAndFactorSources: unimplemented("\(Self.self).deleteProfileAndFactorSources"),
		hasAccountOnNetwork: unimplemented("\(Self.self).hasAccountOnNetwork"),
		getAccountsOnNetwork: unimplemented("\(Self.self).getAccountsOnNetwork"),
		getAccounts: unimplemented("\(Self.self).getAccounts"),
		getPersonas: unimplemented("\(Self.self).getPersonas"),
		getP2PClients: unimplemented("\(Self.self).getP2PClients"),
		getAuthorizedDapps: unimplemented("\(Self.self).getAuthorizedDapps"),
		addAuthorizedDapp: unimplemented("\(Self.self).addAuthorizedDapp"),
		forgetAuthorizedDapp: unimplemented("\(Self.self).forgetAuthorizedDapp"),
		detailsForAuthorizedDapp: unimplemented("\(Self.self).detailsForAuthorizedDapp"),
		updateAuthorizedDapp: unimplemented("\(Self.self).updateAuthorizedDapp"),
		disconnectPersonaFromDapp: unimplemented("\(Self.self).disconnectPersonaFromDapp"),
		addP2PClient: unimplemented("\(Self.self).addP2PClient"),
		deleteP2PClientByID: unimplemented("\(Self.self).deleteP2PClientByID"),
		getAppPreferences: unimplemented("\(Self.self).getAppPreferences"),
		setDisplayAppPreferences: unimplemented("\(Self.self).setDisplayAppPreferences"),
		createUnsavedVirtualEntity: unimplemented("\(Self.self).createUnsavedVirtualEntity"),
		addAccount: unimplemented("\(Self.self).addAccount"),
		addPersona: unimplemented("\(Self.self).addPersona"),
		lookupAccountByAddress: unimplemented("\(Self.self).lookupAccountByAddress")
	)

	public static let noop = Self(
		getFactorSources: { throw NoopError() },
		getCurrentNetworkID: { NetworkID.nebunet },
		getGatewayAPIEndpointBaseURL: { URL(string: "example.com")! },
		getGateways: { .init(current: .nebunet) },
		setGateway: { _ in },
		createEphemeralPrivateProfile: { _ in throw NoopError() },
		injectProfileSnapshot: { _ in },
		commitEphemeralPrivateProfile: { _ in },
		loadProfile: { .success(nil) },
		extractProfileSnapshot: { throw NoopError() },
		deleteProfileAndFactorSources: {},
		hasAccountOnNetwork: { _ in false },
		getAccountsOnNetwork: { _ in throw NoopError() },
		getAccounts: { throw NoopError() },
		getPersonas: { throw NoopError() },
		getP2PClients: { throw NoopError() },
		getAuthorizedDapps: { throw NoopError() },
		addAuthorizedDapp: { _ in throw NoopError() },
		forgetAuthorizedDapp: { _, _ in throw NoopError() },
		detailsForAuthorizedDapp: { _ in throw NoopError() },
		updateAuthorizedDapp: { _ in throw NoopError() },
		disconnectPersonaFromDapp: { _, _, _ in throw NoopError() },
		addP2PClient: { _ in throw NoopError() },
		deleteP2PClientByID: { _ in throw NoopError() },
		getAppPreferences: { throw NoopError() },
		setDisplayAppPreferences: { _ in throw NoopError() },
		createUnsavedVirtualEntity: { _ in throw NoopError() },
		addAccount: { _ in },
		addPersona: { _ in },
		lookupAccountByAddress: { _ in throw NoopError() }
	)
}

// MARK: - ProfileClient + TestDependencyKey
#if DEBUG
extension ProfileClient: TestDependencyKey {
	public static let previewValue: Self = with(.noop) {
		$0.getAccounts = {
			let accounts: [OnNetwork.Account] = [.previewValue0, .previewValue1]
			return NonEmpty(rawValue: IdentifiedArrayOf(uniqueElements: accounts))!
		}
		$0.getPersonas = {
			let accounts: [OnNetwork.Persona] = [.previewValue0, .previewValue1]
			return IdentifiedArrayOf(uniqueElements: accounts)
		}
	}
}
#else // NOT debug
extension ProfileClient: TestDependencyKey {
	public static let previewValue: Self = .noop
}
#endif
