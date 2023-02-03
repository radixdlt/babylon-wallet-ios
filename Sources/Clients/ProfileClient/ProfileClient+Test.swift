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
		getNetworkAndGateway: unimplemented("\(Self.self).getNetworkAndGateway"),
		setNetworkAndGateway: unimplemented("\(Self.self).setNetworkAndGateway"),
		createEphemeralProfileAndUnsavedOnDeviceFactorSource: unimplemented("\(Self.self).createEphemeralProfileAndUnsavedOnDeviceFactorSource"),
		injectProfileSnapshot: unimplemented("\(Self.self).injectProfileSnapshot"),
		commitEphemeralProfileAndPersistOnDeviceFactorSourceMnemonic: unimplemented("\(Self.self).commitEphemeralProfileAndPersistOnDeviceFactorSourceMnemonic"),
		loadProfile: unimplemented("\(Self.self).loadProfile"),
		extractProfileSnapshot: unimplemented("\(Self.self).extractProfileSnapshot"),
		deleteProfileAndFactorSources: unimplemented("\(Self.self).deleteProfileAndFactorSources"),
		hasAccountOnNetwork: unimplemented("\(Self.self).hasAccountOnNetwork"),
		getAccounts: unimplemented("\(Self.self).getAccounts"),
		getPersonas: unimplemented("\(Self.self).getPersonas"),
		getP2PClients: unimplemented("\(Self.self).getP2PClients"),
		getConnectedDapps: unimplemented("\(Self.self).getConnectedDapps"),
		addConnectedDapp: unimplemented("\(Self.self).addConnectedDapp"),
		forgetConnectedDapp: unimplemented("\(Self.self).forgetConnectedDapp"),
		detailsForConnectedDapp: unimplemented("\(Self.self).detailsForConnectedDapp"),
		updateConnectedDapp: unimplemented("\(Self.self).updateConnectedDapp"),
		addP2PClient: unimplemented("\(Self.self).addP2PClient"),
		deleteP2PClientByID: unimplemented("\(Self.self).deleteP2PClientByID"),
		getAppPreferences: unimplemented("\(Self.self).getAppPreferences"),
		setDisplayAppPreferences: unimplemented("\(Self.self).setDisplayAppPreferences"),
		createUnsavedVirtualEntity: unimplemented("\(Self.self).createUnsavedVirtualEntity"),
		addAccount: unimplemented("\(Self.self).addAccount"),
		addPersona: unimplemented("\(Self.self).addPersona"),
		lookupAccountByAddress: unimplemented("\(Self.self).lookupAccountByAddress"),
		signersForAccountsGivenAddresses: unimplemented("\(Self.self).signersForAccountsGivenAddresses")
	)

	public static let noop = Self(
		getFactorSources: { throw NoopError() },
		getCurrentNetworkID: { NetworkID.nebunet },
		getGatewayAPIEndpointBaseURL: { URL(string: "example.com")! },
		getNetworkAndGateway: { AppPreferences.NetworkAndGateway.nebunet },
		setNetworkAndGateway: { _ in },
		createEphemeralProfileAndUnsavedOnDeviceFactorSource: { _ in throw NoopError() },
		injectProfileSnapshot: { _ in },
		commitEphemeralProfileAndPersistOnDeviceFactorSourceMnemonic: { _ in },
		loadProfile: { .success(nil) },
		extractProfileSnapshot: { throw NoopError() },
		deleteProfileAndFactorSources: {},
		hasAccountOnNetwork: { _ in false },
		getAccounts: { throw NoopError() },
		getPersonas: { throw NoopError() },
		getP2PClients: { throw NoopError() },
		getConnectedDapps: { throw NoopError() },
		addConnectedDapp: { _ in throw NoopError() },
		forgetConnectedDapp: { _, _ in throw NoopError() },
		detailsForConnectedDapp: { _ in throw NoopError() },
		updateConnectedDapp: { _ in throw NoopError() },
		addP2PClient: { _ in throw NoopError() },
		deleteP2PClientByID: { _ in throw NoopError() },
		getAppPreferences: { throw NoopError() },
		setDisplayAppPreferences: { _ in throw NoopError() },
		createUnsavedVirtualEntity: { _ in throw NoopError() },
		addAccount: { _ in },
		addPersona: { _ in },
		lookupAccountByAddress: { _ in throw NoopError() },
		signersForAccountsGivenAddresses: { _ in throw NoopError() }
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
