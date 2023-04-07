import ClientPrelude
import EngineToolkit
import Cryptography

extension EngineToolkitClient {
	public func lockFeeCallMethod(
		address: ComponentAddress,
		fee: String = "10"
	) -> CallMethod {
		CallMethod(
			receiver: address,
			methodName: "lock_fee"
		) {
			Decimal_(value: fee)
		}
	}

	public func lockFeeCallMethod(
		faucetForNetwork networkID: NetworkID,
		fee: String = "10"
	) throws -> CallMethod {
		let faucetAddress = try faucetAddress(for: networkID)
		return lockFeeCallMethod(address: faucetAddress, fee: fee)
	}

	public func manifestForFaucet(
		includeLockFeeInstruction: Bool,
		networkID: NetworkID,
		accountAddress: AccountAddress
	) throws -> TransactionManifest {
		try manifestForFaucet(
			includeLockFeeInstruction: includeLockFeeInstruction,
			networkID: networkID,
			componentAddress: .init(address: accountAddress.address)
		)
	}

	/// CALL_METHOD
	///     ComponentAddress("${faucet_component}")
	///     "lock_fee"
	///     Decimal("10");
	///
	/// CALL_METHOD
	///     ComponentAddress("${faucet_component}")
	///     "free";
	///
	/// CALL_METHOD
	///     ComponentAddress("${account_component_address}")
	///     "deposit_batch"
	///     Expression("ENTIRE_WORKTOP");
	public func manifestForFaucet(
		includeLockFeeInstruction: Bool,
		networkID: NetworkID,
		componentAddress: ComponentAddress
	) throws -> TransactionManifest {
		let faucetAddress = try faucetAddress(for: networkID)
		var instructions: [any InstructionProtocol] = [
			CallMethod(
				receiver: faucetAddress,
				methodName: "free"
			),

			CallMethod(
				receiver: componentAddress,
				methodName: "deposit_batch"
			) {
				Expression("ENTIRE_WORKTOP")
			},
		]

		if includeLockFeeInstruction {
			instructions.insert(
				lockFeeCallMethod(address: faucetAddress),
				at: 0
			)
		}
		return .init(instructions: .parsed(instructions.map { $0.embed() }))
	}

	private func faucetAddress(for networkID: NetworkID) throws -> ComponentAddress {
		try knownEntityAddresses(networkID).faucetComponentAddress
	}
}

#if DEBUG
extension EngineToolkitClient {
	public func manifestForCreateFungibleToken(
		networkID: NetworkID,
		accountAddress: AccountAddress,
		tokenDivisivility: UInt8 = 18,
		tokenName: String = "Token Test",
		tokenDescription: String = "A very innovative and important resource.",
		tokenSymbol: String = "TEST",
		initialSupply: String = "21000000",
                tokensCount: Int = 100
        ) throws -> TransactionManifest {
                let faucetAddress = try faucetAddress(for: networkID)
                let tokens = stride(from: 0, to: tokensCount, by: 1).map { _ in
                        CreateFungibleResourceWithInitialSupply(
                                divisibility: tokenDivisivility,
                                metadata: Map_(
                                        keyValueKind: .string,
                                        valueValueKind: .string,
                                        entries: [
                                                [.string("name"), .string(BIP39.WordList.english.randomElement() ?? "Unknown")],
                                                [.string("symbol"), .string(BIP39.WordList.english.randomElement() ?? "Unknown")],
                                                [.string("description"), .string(tokenDescription)],
                                        ]
                                ),

                                accessRules: .init(
                                        keyValueKind: .enum,
                                        valueValueKind: .tuple,
                                        entries: [
                                                [.enum(.init(.string("ResourceMethodAuthKey::Withdraw"))), .tuple(.init(arrayLiteral: .enum(.init(.string("AccessRule::AllowAll"))), .enum(.init(.string("AccessRule::DenyAll")))))],
                                                [.enum(.init(.string("ResourceMethodAuthKey::Deposit"))), .tuple(.init(arrayLiteral: .enum(.init(.string("AccessRule::AllowAll"))), .enum(.init(.string("AccessRule::DenyAll")))))],
                                        ]
                                ),
                                initialSupply: .decimal(.init(value: initialSupply))
                        )
                }
                let instructions: [any InstructionProtocol] = [
                        lockFeeCallMethod(address: faucetAddress)
                ] +
                tokens +
                [
                        CallMethod(receiver: .init(address: accountAddress.address), methodName: "deposit_batch") {
                                Expression(stringLiteral: "ENTIRE_WORKTOP")
                        }
                ]

		return .init(instructions: .parsed(instructions.map { $0.embed() }))
	}

	public func manifestForCreateNonFungibleToken(
		networkID: NetworkID,
		accountAddress: AccountAddress,
		nftName: String = "NFT Test",
		nftDescription: String = "Artsy cool unique NFT",
                tokensCount: Int = 10,
                idsCount: Int = 300
	) throws -> TransactionManifest {
		let faucetAddress = try faucetAddress(for: networkID)
                let ids = stride(from: 0, to: idsCount, by: 1).map {
                        [ManifestASTValue.nonFungibleLocalId(.integer(UInt64($0))), .tuple([.tuple(
                                [.string("Hello World \($0)"), .decimal(.init(value: "\($0)"))]
                        )])]
                }

                let tokens = try stride(from: 0, to: tokensCount, by: 1).map { _ in
                        try CreateNonFungibleResourceWithInitialSupply(
                                idType: .init(.string("NonFungibleIdType::Integer")),
                                schema: [
                                        .tuple([
                                                .array(.init(elementKind: .enum, elements: [])),
                                                .array(.init(elementKind: .tuple, elements: [])),
                                                .array(.init(elementKind: .enum, elements: [])),
                                        ]),
                                        .enum(.init(.u8(0), fields: [.u8(64)])),
                                        .array(.init(elementKind: .string, elements: [])),
                                ],
                                metadata: Map_(
                                        keyValueKind: .string,
                                        valueValueKind: .string,
                                        entries: [
                                                [.string("name"), .string(BIP39.WordList.english.randomElement() ?? "Unknown")],
                                                [.string("description"), .string(nftDescription)],
                                        ]
                                ),
                                accessRules: .init(
                                        keyValueKind: .enum,
                                        valueValueKind: .tuple,
                                        entries: [
                                                [.enum(.init(.string("ResourceMethodAuthKey::Withdraw"))), .tuple(.init(arrayLiteral: .enum(.init(.string("AccessRule::AllowAll"))), .enum(.init(.string("AccessRule::DenyAll")))))],
                                                [.enum(.init(.string("ResourceMethodAuthKey::Deposit"))), .tuple(.init(arrayLiteral: .enum(.init(.string("AccessRule::AllowAll"))), .enum(.init(.string("AccessRule::DenyAll")))))],
                                        ]
                                ),
                                initialSupply: .map(
                                        .init(keyValueKind: .nonFungibleLocalId, valueValueKind: .tuple, entries: ids)
                                )
                        )
                }

		let instructions: [any InstructionProtocol] = [lockFeeCallMethod(address: faucetAddress)] + tokens + [CallMethod(receiver: .init(address: accountAddress.address), methodName: "deposit_batch") {
                        Expression(stringLiteral: "ENTIRE_WORKTOP")
                }]

//			try CreateNonFungibleResourceWithInitialSupply(
//				idType: .init(.string("NonFungibleIdType::Integer")),
//				schema: [
//					.tuple([
//						.array(.init(elementKind: .enum, elements: [])),
//						.array(.init(elementKind: .tuple, elements: [])),
//						.array(.init(elementKind: .enum, elements: [])),
//					]),
//					.enum(.init(.u8(0), fields: [.u8(64)])),
//					.array(.init(elementKind: .string, elements: [])),
//				],
//				metadata: Map_(
//					keyValueKind: .string,
//					valueValueKind: .string,
//					entries: [
//						[.string("name"), .string(nftName)],
//						[.string("description"), .string(nftDescription)],
//					]
//				),
//				accessRules: .init(
//					keyValueKind: .enum,
//					valueValueKind: .tuple,
//					entries: [
//						[.enum(.init(.string("ResourceMethodAuthKey::Withdraw"))), .tuple(.init(arrayLiteral: .enum(.init(.string("AccessRule::AllowAll"))), .enum(.init(.string("AccessRule::DenyAll")))))],
//						[.enum(.init(.string("ResourceMethodAuthKey::Deposit"))), .tuple(.init(arrayLiteral: .enum(.init(.string("AccessRule::AllowAll"))), .enum(.init(.string("AccessRule::DenyAll")))))],
//					]
//				),
//				initialSupply: .map(
//					.init(keyValueKind: .nonFungibleLocalId, valueValueKind: .tuple, entries: ids)
//				)
//			),
//
//			CallMethod(receiver: .init(address: accountAddress.address), methodName: "deposit_batch") {
//				Expression(stringLiteral: "ENTIRE_WORKTOP")
//			},
//		]

		return TransactionManifest(instructions: .parsed(instructions.map { $0.embed() }))
	}
}
#endif // DEBUG
