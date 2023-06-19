#if DEBUG
import Prelude
import Profile

extension Profile.Network.Account {
	public static let previewValue0: Self = try! Self(
		networkID: .nebunet,
		address: .init(
			validatingAddress: "account_sim1cyvgx33089ukm2pl97pv4max0x40ruvfy4lt60yvya744cve475w0q"
		),
		securityState: .unsecured(.init(
			transactionSigning: .init(
				factorSourceID: .device(hash: "09bfa80bcc9b75d6ad82d59730f7b179cbc668ba6ad4008721d5e6a179ff55f1"),
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
			validatingAddress: "account_sim1cyvgx33089ukm2pl97pv4max0x40ruvfy4lt60yvya744cve475w0q"
		),
		securityState: .unsecured(.init(
			transactionSigning: .init(
				factorSourceID: .device(hash: "09bfa80bcc9b75d6ad82d59730f7b179cbc668ba6ad4008721d5e6a179ff55f1"),
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
