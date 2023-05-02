import ClientPrelude
import Cryptography
import EngineToolkit

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
	public func manifestForMultipleCreateFungibleToken(
		networkID: NetworkID,
		accountAddress: AccountAddress,
		tokensCount: Int = 20
	) throws -> TransactionManifest {
		let faucetAddress = try faucetAddress(for: networkID)
		let tokens: [any InstructionProtocol] = stride(from: 0, to: tokensCount, by: 1).map { _ in
			var metdataEntries: [[ManifestASTValue]] = []

			let addName = Bool.random()
			let addSymbol = Bool.random()
			let addIcon = Bool.random()
			let hasSupply = Bool.random()
			let initialSupply = String(Int.random(in: 0 ..< 100_000))
			let description = BIP39.randomPhrase(maxSize: 20)

			if addName {
				// compose name from two strings
				let name = [BIP39.WordList.english.randomElement()?.capitalized ?? "Unknown", BIP39.WordList.english.randomElement() ?? "Unknown"].joined(separator: " ")
				// add Name
				metdataEntries.append([.string("name"), .string(name)])
			}

			if addSymbol {
				// add symbol
				metdataEntries.append([.string("symbol"), .string(BIP39.WordList.english.randomElement()?.capitalized ?? "Unknown")])
			}

			if addIcon {
				metdataEntries.append([
					.string("icon_url"),
					.string("https://c4.wallpaperflare.com/wallpaper/817/534/563/ave-bosque-fantasia-fenix-wallpaper-preview.jpg"),
				])
			}

			metdataEntries.append(
				[.string("description"), .string(description)]
			)

			let metdata = Map_(
				keyValueKind: .string,
				valueValueKind: .string,
				entries: metdataEntries
			)

			let accessRules = Map_(
				keyValueKind: .enum,
				valueValueKind: .tuple,
				entries: [
					[.enum(.init(.string("ResourceMethodAuthKey::Withdraw"))), .tuple(.init(arrayLiteral: .enum(.init(.string("AccessRule::AllowAll"))), .enum(.init(.string("AccessRule::DenyAll")))))],
					[.enum(.init(.string("ResourceMethodAuthKey::Deposit"))), .tuple(.init(arrayLiteral: .enum(.init(.string("AccessRule::AllowAll"))), .enum(.init(.string("AccessRule::DenyAll")))))],
				]
			)

			if hasSupply {
				return CreateFungibleResourceWithInitialSupply(
					divisibility: 18,
					metadata: metdata,
					accessRules: accessRules,
					initialSupply: .decimal(.init(value: initialSupply))
				)
			} else {
				return CreateFungibleResource(
					divisibility: 18,
					metadata: metdata,
					accessRules: accessRules
				)
			}
		}

		let instructions: [any InstructionProtocol] = [
			lockFeeCallMethod(address: faucetAddress),
		] + tokens +
			[
				CallMethod(receiver: .init(address: accountAddress.address), methodName: "deposit_batch") {
					Expression(stringLiteral: "ENTIRE_WORKTOP")
				},
			]

		return .init(instructions: .parsed(instructions.map { $0.embed() }))
	}

	public func manifestForCreateFungibleToken(
		networkID: NetworkID,
		accountAddress: AccountAddress,
		tokenDivisivility: UInt8 = 18,
		tokenName: String = "Token Test",
		description: String = "A very innovative and important resource.",
		tokenSymbol: String = "TEST",
		initialSupply: String = "21000000"
	) throws -> TransactionManifest {
		let faucetAddress = try faucetAddress(for: networkID)
		let instructions: [any InstructionProtocol] = [
			lockFeeCallMethod(address: faucetAddress),

			CreateFungibleResourceWithInitialSupply(
				divisibility: tokenDivisivility,
				metadata: Map_(
					keyValueKind: .string,
					valueValueKind: .string,
					entries: [
						[.string("name"), .string(tokenName)],
						[.string("symbol"), .string(tokenSymbol)],
						[.string("description"), .string(description)],
						[.string("icon_url"), .string("https://c4.wallpaperflare.com/wallpaper/817/534/563/ave-bosque-fantasia-fenix-wallpaper-preview.jpg")],
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
			),

			CallMethod(receiver: .init(address: accountAddress.address), methodName: "deposit_batch") {
				Expression(stringLiteral: "ENTIRE_WORKTOP")
			},
		]

		return .init(instructions: .parsed(instructions.map { $0.embed() }))
	}

	public func manifestForCreateNonFungibleToken(
		networkID: NetworkID,
		accountAddress: AccountAddress,
		nftName: String = "NFT Test",
		nftDescription: String = "Artsy cool unique NFT"
	) throws -> TransactionManifest {
		let faucetAddress = try faucetAddress(for: networkID)
		let instructions: [any InstructionProtocol] = [
			lockFeeCallMethod(address: faucetAddress),

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
						[.string("name"), .string(nftName)],
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
					.init(keyValueKind: .nonFungibleLocalId, valueValueKind: .tuple, entries: [
						[.nonFungibleLocalId(.integer(1)), .tuple([.tuple(
							[.string("Hello World"), .decimal(.init(value: "12"))]
						)])],
					])
				)
			),

			CallMethod(receiver: .init(address: accountAddress.address), methodName: "deposit_batch") {
				Expression(stringLiteral: "ENTIRE_WORKTOP")
			},
		]

		return TransactionManifest(instructions: .parsed(instructions.map { $0.embed() }))
	}

	public func manifestForCreateMultipleNonFungibleToken(
		networkID: NetworkID,
		accountAddress: AccountAddress,
		tokensCount: Int = 10,
		idsCount: Int = 100
	) throws -> TransactionManifest {
		let faucetAddress = try faucetAddress(for: networkID)
		let tokens = try stride(from: 0, to: tokensCount, by: 1).map { _ in
			var metadataEntries: [[ManifestASTValue]] = []
			let shouldAddName = Bool.random()
			if shouldAddName {
				metadataEntries.append(
					[.string("name"), .string(BIP39.randomPhrase(maxSize: 5))]
				)
			}

			metadataEntries.append(
				[.string("description"), .string(BIP39.randomPhrase(maxSize: 20))]
			)

			let nftIds = stride(from: 0, to: idsCount, by: 1).map {
				[ManifestASTValue.nonFungibleLocalId(.integer(UInt64($0))), .tuple([.tuple(
					[.string("Hello World \($0)"), .decimal(.init(value: "\($0)"))]
				)])]
			}

			return try CreateNonFungibleResourceWithInitialSupply(
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
					entries: metadataEntries
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
					.init(keyValueKind: .nonFungibleLocalId, valueValueKind: .tuple, entries: nftIds)
				)
			)
		}

		let instructions: [any InstructionProtocol] = [lockFeeCallMethod(address: faucetAddress)] + tokens + [CallMethod(receiver: .init(address: accountAddress.address), methodName: "deposit_batch") {
			Expression(stringLiteral: "ENTIRE_WORKTOP")
		}]

		return TransactionManifest(instructions: .parsed(instructions.map { $0.embed() }))
	}
}

extension BIP39 {
	static func randomPhrase(maxSize: Int) -> String {
		stride(from: 0, to: Int.random(in: 1 ..< maxSize), by: 1)
			.compactMap { _ in BIP39.WordList.english.randomElement() }
			.joined(separator: " ")
	}
}
#endif // DEBUG
