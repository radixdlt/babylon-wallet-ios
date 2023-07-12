import EngineToolkitUniFFI

// MARK: - Mutation

/// NOTE: This is temporary code - RET will soon add a dedidcated ManifestBuilder to be used.
///
extension TransactionManifest {
	public func withInstructionAdded(_ instruction: Instruction, at index: Int) throws -> TransactionManifest {
		try .init(
			instructions: instructions().withInstructionAdded(instruction, at: index),
			blobs: blobs()
		)
	}

	public func withLockFeeCallMethodAdded(
		address: Address,
		fee: String = "10"
	) throws -> TransactionManifest {
		try withInstructionAdded(
			.lockFeeCall(address: address, fee: fee),
			at: 0
		)
	}
}

// MARK: - Custom Manifests
extension TransactionManifest {
	public static func manifestForFaucet(
		includeLockFeeInstruction: Bool,
		networkID: NetworkID,
		componentAddress: Address
	) throws -> TransactionManifest {
		try .init(
			instructions: .faucet(
				includeLockFeeInstruction: includeLockFeeInstruction,
				networkID: networkID,
				componentAddress: componentAddress
			),
			blobs: []
		)
	}

	public static func manifestForCreateNonFungibleToken(
		account: AccountAddress,
		network: NetworkID
	) throws -> TransactionManifest {
		try .init(instructions: .createNonFungibleToken(account: account, network: network), blobs: [])
	}

	public static func manifestForCreateMultipleNonFungibleTokens(
		account: AccountAddress,
		network: NetworkID
	) throws -> TransactionManifest {
		try .init(instructions: .createMultipleNonFungibleTokens(account: account, network: network), blobs: [])
	}

	public static func manifestForCreateFungibleToken(
		account: AccountAddress,
		network: NetworkID
	) throws -> TransactionManifest {
		try .init(instructions: .createFungibleToken(account: account, network: network), blobs: [])
	}

	public static func manifestForCreateMultipleFungibleTokens(
		account: AccountAddress,
		network: NetworkID
	) throws -> TransactionManifest {
		try .init(instructions: .createMultipleFungibleTokens(account: account, network: network), blobs: [])
	}

	public static func manifestForOwnerKeys(
		address: String,
		keyHashes: [PublicKeyHash],
		networkID: NetworkID
	) throws -> TransactionManifest {
		try .init(instructions: .ownerKeys(address: address, keyHashes: keyHashes, networkID: networkID), blobs: [])
	}
}

extension Instructions {
	public func withInstructionAdded(_ instruction: Instruction, at index: Int) throws -> Instructions {
		var instructionList = self.instructionsList()
		instructionList.insert(instruction, at: index)
		return try .fromInstructions(instructions: instructionList, networkId: self.networkId())
	}

	public func withLockFeeCallMethodAdded(
		address: Address,
		fee: String = "10"
	) throws -> Instructions {
		try withInstructionAdded(
			.lockFeeCall(address: address, fee: fee),
			at: 0
		)
	}

	static func faucetAddress(networkID: NetworkID) -> EngineToolkitUniFFI.Address {
		utilsKnownAddresses(networkId: networkID.rawValue).componentAddresses.faucet
	}

	static func from(rawInstructions: [String], network: NetworkID) throws -> Instructions {
		try .fromString(string: rawInstructions.joined(separator: "\n"), blobs: [], networkId: network.rawValue)
	}

	static func createFungibleToken(
		account: AccountAddress,
		network: NetworkID
	) throws -> Instructions {
		let instructions: [String] = [Instruction.fungibleWithInitialSupplyInstruction(), Instruction.depositBatch(account: account)]
		return try .from(rawInstructions: instructions, network: network)
	}

	static func createMultipleFungibleTokens(
		account: AccountAddress,
		network: NetworkID
	) throws -> Instructions {
		let instructions = [String](repeating: Instruction.fungibleWithInitialSupplyInstruction(), count: 20) + [Instruction.depositBatch(account: account)]
		return try .from(rawInstructions: instructions, network: network)
	}

	static func createMultipleNonFungibleTokens(
		account: AccountAddress,
		network: NetworkID
	) throws -> Instructions {
		let instructions = [String](repeating: Instruction.noFungibleWithInitialSupplyInstruction(), count: 10) + [Instruction.depositBatch(account: account)]
		return try .from(rawInstructions: instructions, network: network)
	}

	static func createNonFungibleToken(
		account: AccountAddress,
		network: NetworkID
	) throws -> Instructions {
		let instructions: [String] = [Instruction.noFungibleWithInitialSupplyInstruction(), Instruction.depositBatch(account: account)]
		return try .from(rawInstructions: instructions, network: network)
	}

	static func faucet(
		includeLockFeeInstruction: Bool,
		networkID: NetworkID,
		componentAddress: Address
	) throws -> Instructions {
		let faucet = faucetAddress(networkID: networkID)
		var rawInstructions = [Instruction.free(address: faucet), Instruction.tryDepositBatchOrAbort(componentAddress: componentAddress)]
		let instructions = try Instructions.from(rawInstructions: rawInstructions, network: networkID)

		if includeLockFeeInstruction {
			return try instructions.withLockFeeCallMethodAdded(address: componentAddress)
		}
		return instructions
	}

	static func ownerKeys(address: String, keyHashes: [PublicKeyHash], networkID: NetworkID) throws -> Instructions {
		try .from(rawInstructions: [Instruction.ownerKeysMetadata(address: address, keyHashes: keyHashes)], network: networkID)
	}
}

extension Instruction {
	static func lockFeeCall(
		address: Address,
		fee: String = "10"
	) throws -> Instruction {
		try .callMethod(address: .init(address: address.address), methodName: "lock_fee", args: .tupleValue(fields: [.decimalValue(value: .init(value: fee))]))
	}

	static func depositBatch(account: AccountAddress) -> String {
		"""
		CALL_METHOD
		    Address("\(account.address)")
		    "deposit_batch"
		    Expression("ENTIRE_WORKTOP");
		"""
	}

	static func free(address: EngineToolkitUniFFI.Address) -> String {
		"""
		CALL_METHOD
		    Address("\(address.addressString())")
		    "free";
		"""
	}

	static func tryDepositBatchOrAbort(componentAddress: Address) -> String {
		"""
		                CALL_METHOD
		                    Address("\(componentAddress.address)")
		                    "try_deposit_batch_or_abort"
		                    Expression("ENTIRE_WORKTOP");
		"""
	}

	static func publicKeyHash(_ hash: PublicKeyHash) throws -> String {
		try """
		Enum<\(hash.discriminator)>(
		Bytes("\(hash.bytes().hex)")
		)
		"""
	}

	static func ownerKeysMetadata(address: String, keyHashes: [PublicKeyHash]) throws -> String {
		let hashInstructions = try keyHashes.map(publicKeyHash(_:))
		return """
		SET_METADATA
		    Address("\(address)")
		    "owner_keys"
		    Enum<Metadata::PublicKeyHashArray>(Array<Enum>(
		\(String(hashInstructions.joined(separator: ",\n")))
		    ));
		"""
	}

	static func fungibleWithInitialSupplyInstruction() -> String {
		"""
		                CREATE_FUNGIBLE_RESOURCE_WITH_INITIAL_SUPPLY
		                    18u8
		                    Map<String, Enum>(
		                        "name" => Enum<Metadata::String>("MyResource"),
		                        "symbol" => Enum<Metadata::String>("VIP"),
		                        "description" => Enum<Metadata::String>("A very innovative and important resource"),
		                        "icon_url" => Enum<Metadata::String>("https://i.imgur.com/9YQ9Z0x.png")
		                    )
		                    Map<Enum, Tuple>(

		                        Enum<ResourceMethodAuthKey::Withdraw>() => Tuple(Enum<AccessRule::AllowAll>(), Enum<AccessRule::DenyAll>()),
		                        Enum<ResourceMethodAuthKey::Deposit>() => Tuple(Enum<AccessRule::AllowAll>(), Enum<AccessRule::DenyAll>())
		                    )
		                    Decimal("21000000");
		"""
	}

	static func noFungibleWithInitialSupplyInstruction() -> String {
		"""
		CREATE_NON_FUNGIBLE_RESOURCE_WITH_INITIAL_SUPPLY
		    Enum<1u8>()
		    Tuple(
		        Tuple(
		            Array<Enum>(),
		            Array<Tuple>(),
		            Array<Enum>()
		        ),
		        Enum<0u8>(
		            64u8
		        ),
		        Array<String>()
		    )
		    Map<String, Enum>(
		        "name" => Enum<0u8>(
		            "MyResource"
		        ),
		        "description" => Enum<0u8>(
		            "A very innovative and important resource"
		        ),
		        "icon_url" => Enum<0u8>(
		            "https://i.imgur.com/9YQ9Z0x.png"
		        )
		    )
		    Map<Enum, Tuple>(
		        Enum<4u8>() => Tuple(
		            Enum<0u8>(),
		            Enum<1u8>()
		        ),
		        Enum<5u8>() => Tuple(
		            Enum<0u8>(),
		            Enum<1u8>()
		        )
		    )
		    Map<NonFungibleLocalId, Tuple>(
		        NonFungibleLocalId("#1#") => Tuple(
		            Tuple(
		                "https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/Filling+Station+Breakfast-large.jpg",
		                Decimal("0")
		            )
		        ),
		        NonFungibleLocalId("#2#") => Tuple(
		            Tuple(
		                "https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/Filling+Station+Breakfast-large.jpg",
		                Decimal("1")
		            )
		        ),
		        NonFungibleLocalId("#3#") => Tuple(
		            Tuple(
		                "https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/Filling+Station+Breakfast-medium.jpg",
		                Decimal("2")
		            )
		        ),
		        NonFungibleLocalId("#4#") => Tuple(
		            Tuple(
		                "https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/Filling+Station+Breakfast-small.jpg",
		                Decimal("3")
		            )
		        ),
		        NonFungibleLocalId("#5#") => Tuple(
		            Tuple(
		                "https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/Frame 6-large.png",
		                Decimal("4")
		            )
		        ),
		        NonFungibleLocalId("#6#") => Tuple(
		            Tuple(
		                "https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/Frame 6-medium.png",
		                Decimal("5")
		            )
		        ),
		        NonFungibleLocalId("#7#") => Tuple(
		            Tuple(
		                "https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/Frame 6-small.png",
		                Decimal("6")
		            )
		        ),
		        NonFungibleLocalId("#8#") => Tuple(
		            Tuple(
		                "https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/Fried Kway Teow-large.jpg",
		                Decimal("7")
		            )
		        ),
		        NonFungibleLocalId("#9#") => Tuple(
		            Tuple(
		                "https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/Fried Kway Teow-medium.jpg",
		                Decimal("8")
		            )
		        ),
		        NonFungibleLocalId("#10#") => Tuple(
		            Tuple(
		                "https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/Fried Kway Teow-small.jpg",
		                Decimal("9")
		            )
		        ),
		        NonFungibleLocalId("#11#") => Tuple(
		            Tuple(
		                "https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/ICON-transparency.png",
		                Decimal("10")
		            )
		        ),
		        NonFungibleLocalId("#12#") => Tuple(
		            Tuple(
		                "https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/KL Haze-large.jpg",
		                Decimal("11")
		            )
		        ),
		        NonFungibleLocalId("#13#") => Tuple(
		            Tuple(
		                "https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/KL Haze-medium.jpg",
		                Decimal("12")
		            )
		        ),
		        NonFungibleLocalId("#14#") => Tuple(
		            Tuple(
		                "https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/KL Haze-small.jpg",
		                Decimal("13")
		            )
		        ),
		        NonFungibleLocalId("#15#") => Tuple(
		            Tuple(
		                "https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/modern_kunst_museum_pano-2.jpg",
		                Decimal("14")
		            )
		        ),
		        NonFungibleLocalId("#16#") => Tuple(
		            Tuple(
		                "https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/modern_kunst_museum_pano-3.jpg",
		                Decimal("15")
		            )
		        ),
		        NonFungibleLocalId("#17#") => Tuple(
		            Tuple(
		                "https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/modern_kunst_museum_pano.jpg",
		                Decimal("16")
		            )
		        ),
		        NonFungibleLocalId("#18#") => Tuple(
		            Tuple(
		                "https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/scryptonaut_patch.svg",
		                Decimal("17")
		            )
		        )
		    )
		;
		"""
	}
}

extension PublicKeyHash {
	/// https://rdxworks.slack.com/archives/C031A0V1A1W/p1683275008777499?thread_ts=1683221252.228129&cid=C031A0V1A1W
	var discriminator: String {
		switch self {
		case .ecdsaSecp256k1: return "0u8"
		case .eddsaEd25519: return "1u8"
		}
	}

	func bytes() throws -> [UInt8] {
		switch self {
		case let .ecdsaSecp256k1(value), let .eddsaEd25519(value):
			return value
		}
	}
}
