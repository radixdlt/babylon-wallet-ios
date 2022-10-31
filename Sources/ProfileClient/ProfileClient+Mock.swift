import Collections
import Foundation
import Mnemonic
import NonEmpty
import Profile

#if DEBUG
public extension ProfileClient {
	static func mock() -> Self {
		Self(
			getCurrentNetworkID: { NetworkID.primary },
			setCurrentNetworkID: { _ in },
			createNewProfile: { req in
				try! await Profile.new(
					networkID: .primary,
					mnemonic: req.curve25519FactorSourceMnemonic
				)
			},
			injectProfile: { _ in /* Noop */ },
			extractProfileSnapshot: { fatalError("Impl me") },
			deleteProfileSnapshot: { /* Noop */ },
			getAccounts: {
				let accounts: [OnNetwork.Account] = [
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
					),
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
					),
				]

				return NonEmpty(rawValue: OrderedSet(accounts))!
			},
			getAppPreferences: {
				fatalError()
			},
			setDisplayAppPreferences: { _ in
				fatalError()
			},
			createAccount: { _ in
				fatalError()
			}
		)
	}
}

#endif // DEBUG
