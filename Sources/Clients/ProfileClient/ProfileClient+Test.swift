import ClientPrelude
import Cryptography
import Profile

public extension DependencyValues {
	var profileClient: ProfileClient {
		get { self[ProfileClient.self] }
		set { self[ProfileClient.self] = newValue }
	}
}

#if DEBUG

// MARK: - ProfileClient + TestDependencyKey
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

	public static let testValue = Self(
		getCurrentNetworkID: unimplemented("\(Self.self).getCurrentNetworkID"),
		getGatewayAPIEndpointBaseURL: unimplemented("\(Self.self).getGatewayAPIEndpointBaseURL"),
		getNetworkAndGateway: unimplemented("\(Self.self).getNetworkAndGateway"),
		setNetworkAndGateway: unimplemented("\(Self.self).setNetworkAndGateway"),
		createNewProfile: unimplemented("\(Self.self).createNewProfile"),
		loadProfile: unimplemented("\(Self.self).loadProfile"),
		extractProfileSnapshot: unimplemented("\(Self.self).extractProfileSnapshot"),
		deleteProfileAndFactorSources: unimplemented("\(Self.self).deleteProfileAndFactorSources"),
		hasAccountOnNetwork: unimplemented("\(Self.self).hasAccountOnNetwork"),
		getAccounts: unimplemented("\(Self.self).getAccounts"),
		getPersonas: unimplemented("\(Self.self).getPersonas"),
		getP2PClients: unimplemented("\(Self.self).getP2PClients"),
		getConnectedDapps: unimplemented("\(Self.self).getConnectedDapps"),
		addConnectedDapp: unimplemented("\(Self.self).addConnectedDapp"),
		updateConnectedDapp: unimplemented("\(Self.self).updateConnectedDapp"),
		addP2PClient: unimplemented("\(Self.self).addP2PClient"),
		deleteP2PClientByID: unimplemented("\(Self.self).deleteP2PClientByID"),
		getAppPreferences: unimplemented("\(Self.self).getAppPreferences"),
		setDisplayAppPreferences: unimplemented("\(Self.self).setDisplayAppPreferences"),
		createUnsavedVirtualAccount: unimplemented("\(Self.self).createUnsavedVirtualAccount"),
		createUnsavedVirtualPersona: unimplemented("\(Self.self).createUnsavedVirtualPersona"),
		addAccount: unimplemented("\(Self.self).addAccount"),
		addPersona: unimplemented("\(Self.self).addPersona"),
		lookupAccountByAddress: unimplemented("\(Self.self).lookupAccountByAddress"),
		signersForAccountsGivenAddresses: unimplemented("\(Self.self).signersForAccountsGivenAddresses")
	)
}

public extension ProfileClient {
	static let noop = Self(
		getCurrentNetworkID: { NetworkID.nebunet },
		getGatewayAPIEndpointBaseURL: { URL(string: "example.com")! },
		getNetworkAndGateway: { AppPreferences.NetworkAndGateway.nebunet },
		setNetworkAndGateway: { _ in },
		createNewProfile: { _ in
			OnNetwork.Account.previewValue0
		},
		loadProfile: { .success(nil) },
		extractProfileSnapshot: { throw NoopError() },
		deleteProfileAndFactorSources: {},
		hasAccountOnNetwork: { _ in false },
		getAccounts: { throw NoopError() },
		getPersonas: { throw NoopError() },
		getP2PClients: { throw NoopError() },
		getConnectedDapps: { throw NoopError() },
		addConnectedDapp: { _ in throw NoopError() },
		updateConnectedDapp: { _ in throw NoopError() },
		addP2PClient: { _ in throw NoopError() },
		deleteP2PClientByID: { _ in throw NoopError() },
		getAppPreferences: { throw NoopError() },
		setDisplayAppPreferences: { _ in throw NoopError() },
		createUnsavedVirtualAccount: { _ in throw NoopError() },
		createUnsavedVirtualPersona: { _ in throw NoopError() },
		addAccount: { _ in },
		addPersona: { _ in },
		lookupAccountByAddress: { _ in .previewValue0 },
		signersForAccountsGivenAddresses: { _ in throw NoopError() }
	)
}
#endif
