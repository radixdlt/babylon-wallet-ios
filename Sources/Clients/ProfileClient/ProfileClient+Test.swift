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
	// TODO: make every endpoint no-op
	public static let previewValue = Self(
		getCurrentNetworkID: { NetworkID.primary },
		getGatewayAPIEndpointBaseURL: { URL(string: "example.com")! },
		getNetworkAndGateway: { AppPreferences.NetworkAndGateway.primary },
		setNetworkAndGateway: { _ in },
		createNewProfileWithOnLedgerAccount: { req, _ in
			try! await Profile.new(
				networkAndGateway: .primary,
				mnemonic: req.curve25519FactorSourceMnemonic
			)
		},
		injectProfile: { _ in /* Noop */ },
		extractProfileSnapshot: { fatalError("Impl me") },
		deleteProfileAndFactorSources: { /* Noop */ },
		getAccounts: {
			let accounts: [OnNetwork.Account] = [.placeholder0, .placeholder1]
			return NonEmpty(rawValue: OrderedSet(accounts))!
		},
		getP2PClients: { fatalError() },
		addP2PClient: { _ in fatalError() },
		deleteP2PClientByID: { _ in fatalError() },
		getAppPreferences: {
			fatalError()
		},
		setDisplayAppPreferences: { _ in
			fatalError()
		},
		createOnLedgerAccount: { _, _ in
			fatalError()
		},
		lookupAccountByAddress: { _ in
			.placeholder0
		},
		signTransaction: { _ in
			struct MockError: LocalizedError {
				let errorDescription: String? = "Transaction signing failed!"
			}
			throw MockError()
		}
	)

	public static let testValue = Self(
		getCurrentNetworkID: unimplemented("\(Self.self).getCurrentNetworkID"),
		getGatewayAPIEndpointBaseURL: unimplemented("\(Self.self).getGatewayAPIEndpointBaseURL"),
		getNetworkAndGateway: unimplemented("\(Self.self).getNetworkAndGateway"),
		setNetworkAndGateway: unimplemented("\(Self.self).setNetworkAndGateway"),
		createNewProfileWithOnLedgerAccount: { _, _ in throw UnimplementedError(description: "\(Self.self).createNewProfileWithOnLedgerAccount is unimplemented") },
		injectProfile: unimplemented("\(Self.self).injectProfile"),
		extractProfileSnapshot: unimplemented("\(Self.self).extractProfileSnapshot"),
		deleteProfileAndFactorSources: unimplemented("\(Self.self).deleteProfileAndFactorSources"),
		getAccounts: unimplemented("\(Self.self).getAccounts"),
		getP2PClients: unimplemented("\(Self.self).getP2PClients"),
		addP2PClient: unimplemented("\(Self.self).addP2PClient"),
		deleteP2PClientByID: unimplemented("\(Self.self).deleteP2PClientByID"),
		getAppPreferences: unimplemented("\(Self.self).getAppPreferences"),
		setDisplayAppPreferences: unimplemented("\(Self.self).setDisplayAppPreferences"),
		createOnLedgerAccount: { _, _ in throw UnimplementedError(description: "\(Self.self).createOnLedgerAccount is unimplemented") },
		lookupAccountByAddress: unimplemented("\(Self.self).lookupAccountByAddress"),
		signTransaction: unimplemented("\(Self.self).signTransaction")
	)
}

public struct UnimplementedError: Swift.Error {
	public let description: String
}

#endif
