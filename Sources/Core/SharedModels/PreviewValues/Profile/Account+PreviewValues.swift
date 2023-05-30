#if DEBUG
import Prelude
import Profile

extension Profile.Network.Account {
	public static let previewValue0: Self = try! Self(
		networkID: .nebunet,
		address: .init(
			address: "account_tdx_c_1px9r7zkwfrve4cv3xlehwz8k29vp2q2dp6jhdx2mlkxsh4kqke"
		),
		securityState: .unsecured(.init(
			transactionSigning: .init(
				factorSourceID: .init(hex: "de09bfa80bcc9b75d6ad82d59730f7b179cbc668ba6ad4008721d5e6a179ff55f1"),
				publicKey: .eddsaEd25519(.init(
					compressedRepresentation: Data(
						hex: "7bf9f97c0cac8c6c112d716069ccc169283b9838fa2f951c625b3d4ca0a8f05b")
				)),
				derivationPath: .accountPath(.init(derivationPath: "m/44H/1022H/10H/525H/1460H/0H"))
			)
		)),
		appearanceID: ._0,
		displayName: "Main"
	)

	public static let previewValue1: Self = try! Self(
		networkID: .nebunet,
		address: .init(
			address: "account_tdx_a_1qvlrgnqrvk6tzmg8z6lusprl3weupfkmu52gkfhmncjsnhn0kp"
		),
		securityState: .unsecured(.init(
			transactionSigning: .init(
				factorSourceID: .init(hex: "de09bfa80bcc9b75d6ad82d59730f7b179cbc668ba6ad4008721d5e6a179ff55f1"),
				publicKey: .eddsaEd25519(.init(
					compressedRepresentation: Data(
						hex: "b862c4ef84a4a97c37760636f6b94d1fba7b4881ac15a073f6c57e2996bbeca8")
				)),
				derivationPath: .accountPath(.init(derivationPath: "m/44H/1022H/10H/525H/1460H/1H"))
			))),
		appearanceID: ._1,
		displayName: "Secondary"
	)
}

extension Profile.Network.Accounts {
	public static let previewValue: Self = .init(rawValue: .init(uniqueElements: [Profile.Network.Account.previewValue0, Profile.Network.Account.previewValue1]))!
}

#endif // DEBUG
