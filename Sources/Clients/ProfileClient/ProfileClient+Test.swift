import Collections
import Dependencies
import Foundation
import Mnemonic
import NonEmpty
import Profile
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
			let accounts: [OnNetwork.Account] = [.mocked0, .mocked1]
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
			.mocked0
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

public extension OnNetwork.Account {
	static var mocked0: Self {
		try! OnNetwork.Account(
			address: OnNetwork.Account.EntityAddress(
				address: "account_tdx_a_1qwv0unmwmxschqj8sntg6n9eejkrr6yr6fa4ekxazdzqhm6wy5"
			),
			securityState: .unsecured(.init(
				genesisFactorInstance: .curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorInstance(.init(
					factorSourceReference: .init(
						factorSourceKind: .curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSourceKind,
						factorSourceID: "09bfa80bcc9b75d6ad82d59730f7b179cbc668ba6ad4008721d5e6a179ff55f1"
					),
					publicKey: .eddsaEd25519(.init(
						compressedRepresentation: Data(
							hex: "7bf9f97c0cac8c6c112d716069ccc169283b9838fa2f951c625b3d4ca0a8f05b")
					)),
					derivationPath: .accountPath(.init(derivationPath: "m/44H/1022H/10H/525H/0H/1238H"))
				)
				)
			)),
			index: 0,
			derivationPath: .init(derivationPath: "m/44H/1022H/10H/525H/0H/1238H"),
			displayName: "Main"
		)
	}

	static var mocked1: Self {
		try! OnNetwork.Account(
			address: OnNetwork.Account.EntityAddress(
				address: "account_tdx_a_1qvlrgnqrvk6tzmg8z6lusprl3weupfkmu52gkfhmncjsnhn0kp"
			),
			securityState: .unsecured(.init(
				genesisFactorInstance: .curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorInstance(.init(
					factorSourceReference: .init(
						factorSourceKind: .curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSourceKind,
						factorSourceID: "09bfa80bcc9b75d6ad82d59730f7b179cbc668ba6ad4008721d5e6a179ff55f1"
					),
					publicKey: .eddsaEd25519(.init(
						compressedRepresentation: Data(
							hex: "b862c4ef84a4a97c37760636f6b94d1fba7b4881ac15a073f6c57e2996bbeca8")
					)),
					derivationPath: .accountPath(.init(derivationPath: "m/44H/1022H/10H/525H/1H/1238H"))
				)
				)
			)),
			index: 1,
			derivationPath: .init(derivationPath: "m/44H/1022H/10H/525H/1H/1238H"),
			displayName: "Secondary"
		)
	}
}
#endif
