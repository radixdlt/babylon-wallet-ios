#if DEBUG
import Prelude
import Profile

extension Profile.Network.Persona {
	public static let previewValue0: Self = try! Self(
		networkID: .nebunet,
		address: .init(
			validatingAddress: "identity_tdx_21_12tljxea3s0mse52jmpvsphr0haqs86sung8d3qlhr763nxttj59650"
		),
		securityState: .unsecured(.init(
			transactionSigning: .init(
				factorSourceID: .device(hash: "09bfa80bcc9b75d6ad82d59730f7b179cbc668ba6ad4008721d5e6a179ff55f1"),
				publicKey: .eddsaEd25519(.init(
					compressedRepresentation: Data(
						hex: "7bf9f97c0cac8c6c112d716069ccc169283b9838fa2f951c625b3d4ca0a8f05b")
				)),
				derivationPath: .identityPath(.init(derivationPath: "m/44H/1022H/10H/618H/1460H/0H"))
			)
		)),
		displayName: "Alan",
		personaData: .init(
			name: .init(
				id: .init(uuidString: "00000000-0000-0000-0000-000000000000")!,
				value: .init(
					given: "Alan",
					family: "Turing",
					variant: .western
				)
			)
		)
	)

	public static let previewValue1: Self = try! Self(
		networkID: .nebunet,
		address: .init(
			validatingAddress: "identity_tdx_a_1qvlrgnqrvk6tzmg8z6lusprl3weupfkmu52gkfhmncjsnhn0kp"
		),
		securityState: .unsecured(.init(
			transactionSigning: .init(
				factorSourceID: .device(hash: "09bfa80bcc9b75d6ad82d59730f7b179cbc668ba6ad4008721d5e6a179ff55f1"),
				publicKey: .eddsaEd25519(.init(
					compressedRepresentation: Data(
						hex: "b862c4ef84a4a97c37760636f6b94d1fba7b4881ac15a073f6c57e2996bbeca8")
				)),
				derivationPath: .identityPath(.init(derivationPath: "m/44H/1022H/10H/618H/1460H/1H"))
			)
		)),
		displayName: "Rick",
		personaData: .init(
			name: .init(
				id: .init(uuidString: "00000000-0000-0000-0000-000000000000")!,
				value: .init(
					given: "Rick",
					family: "Sanchez",
					variant: .western
				)
			)
		)
	)
}
#endif // DEBUG
