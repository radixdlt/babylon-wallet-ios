import Collections
import Dependencies
import Foundation
import Mnemonic
import NonEmpty
import Profile
import SharedModels
import XCTestDynamicOverlay

public extension DependencyValues {
	var profileClient: ProfileClient {
		get { self[ProfileClient.self] }
		set { self[ProfileClient.self] = newValue }
	}
}

#if DEBUG

// MARK: - ProfileClient + TestDependencyKey
extension ProfileClient: TestDependencyKey {
	public static let previewValue = Self.noop

	public static let testValue = Self(
		getCurrentNetworkID: unimplemented("\(Self.self).getCurrentNetworkID"),
		getGatewayAPIEndpointBaseURL: unimplemented("\(Self.self).getGatewayAPIEndpointBaseURL"),
		getNetworkAndGateway: unimplemented("\(Self.self).getNetworkAndGateway"),
		setNetworkAndGateway: unimplemented("\(Self.self).setNetworkAndGateway"),
		createNewProfile: unimplemented("\(Self.self).createNewProfile"),
		injectProfile: unimplemented("\(Self.self).injectProfile"),
		extractProfileSnapshot: unimplemented("\(Self.self).extractProfileSnapshot"),
		deleteProfileAndFactorSources: unimplemented("\(Self.self).deleteProfileAndFactorSources"),
		hasAccountOnNetwork: unimplemented("\(Self.self).hasAccountOnNetwork"),
		getAccounts: unimplemented("\(Self.self).getAccounts"),
		getP2PClients: unimplemented("\(Self.self).getP2PClients"),
		addP2PClient: unimplemented("\(Self.self).addP2PClient"),
		deleteP2PClientByID: unimplemented("\(Self.self).deleteP2PClientByID"),
		getAppPreferences: unimplemented("\(Self.self).getAppPreferences"),
		setDisplayAppPreferences: unimplemented("\(Self.self).setDisplayAppPreferences"),
		createVirtualAccount: unimplemented("\(Self.self).createVirtualAccount"),
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
		createNewProfile: { req in
			try! await Profile.new(
				networkAndGateway: req.networkAndGateway,
				mnemonic: req.curve25519FactorSourceMnemonic
			)
		},
		injectProfile: { _ in },
		extractProfileSnapshot: { throw CancellationError() },
		deleteProfileAndFactorSources: {},
		hasAccountOnNetwork: { _ in false },
		getAccounts: {
			let accounts: [OnNetwork.Account] = [.placeholder0, .placeholder1]
			return NonEmpty(rawValue: OrderedSet(accounts))!
		},
		getP2PClients: { throw CancellationError() },
		addP2PClient: { _ in throw CancellationError() },
		deleteP2PClientByID: { _ in throw CancellationError() },
		getAppPreferences: { throw CancellationError() },
		setDisplayAppPreferences: { _ in throw CancellationError() },
		createVirtualAccount: { _ in throw CancellationError() },
		lookupAccountByAddress: { _ in
			.placeholder0
		},
		signersForAccountsGivenAddresses: { _ in
			struct MockError: LocalizedError {
				let errorDescription: String? = "Failed to get signers for addresses"
			}
			throw MockError()
		}
	)
}
#endif
