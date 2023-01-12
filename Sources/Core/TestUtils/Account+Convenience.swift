import Prelude
import Profile

public extension OnNetwork.Account {
	static var testValue: Self {
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
}
