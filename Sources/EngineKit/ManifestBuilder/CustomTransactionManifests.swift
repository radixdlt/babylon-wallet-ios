import EngineToolkit

extension ManifestBuilder {
	public static func manifestForFaucet(
		includeLockFeeInstruction: Bool,
		networkID: NetworkID,
		componentAddress: Address
	) throws -> TransactionManifest {
		try make {
			if includeLockFeeInstruction {
				faucetLockFee()
			}
			faucetFreeXrd()
			try accountTryDepositBatchOrAbort(componentAddress.intoEngine(), nil)
		}
		.build(networkId: networkID.rawValue)
	}

	public static func manifestForCreateFungibleToken(
		account: AccountAddress,
		networkID: NetworkID
	) throws -> TransactionManifest {
		try ManifestBuilder()
			.createFungibleResourceManager(
				ownerRole: .none,
				trackTotalSupply: true,
				divisibility: 1,
				initialSupply: .init(value: "100000"),
				resourceRoles: .init(mintRoles: nil, burnRoles: nil, freezeRoles: nil, recallRoles: nil, withdrawRoles: nil, depositRoles: nil),
				metadata: .init(
					init: [
						"name": .init(value: .stringValue(value: "MyResource"), lock: false),
						"symbol": .init(value: .stringValue(value: "VIP"), lock: false),
						"description": .init(value: .stringValue(value: "A very innovative and important resource"), lock: false),
						"icon_url": .init(value: .urlValue(value: "https://i.imgur.com/A2itmif.jpeg"), lock: false),
					],
					roles: [:]
				),
				addressReservation: nil
			)
			.accountTryDepositBatchOrAbort(accountAddress: account.intoEngine(), authorizedDepositorBadge: nil)
			.build(networkId: networkID.rawValue)
	}
}
