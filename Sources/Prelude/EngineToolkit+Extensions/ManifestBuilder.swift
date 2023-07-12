import EngineToolkitUniFFI

extension TransactionManifest {
	public func withInstructionAdded(_ instruction: Instruction, at index: Int) throws -> TransactionManifest {
		var instructionList = instructions().instructionsList()
		instructionList.insert(instruction, at: index)

		return try .init(
			instructions: .fromInstructions(instructions: instructionList, networkId: instructions().networkId()),
			blobs: blobs()
		)
	}

	public func withLockFeeCallMethodAdded(
		address: Address,
		fee: String = "10"
	) throws -> TransactionManifest {
		try withInstructionAdded(
			.callMethod(
				address: .init(address: address.address),
				methodName: "lock_fee",
				args: .tupleValue(fields: [.decimalValue(value: .init(value: fee))])
			),
			at: 0
		)
	}

	public static func manifestForFaucet(
		includeLockFeeInstruction: Bool,
		networkID: NetworkID,
		componentAddress: Address
	) throws -> TransactionManifest {
		let faucet = utilsKnownAddresses(networkId: networkID.rawValue).componentAddresses.faucet
		let raw = """
		CALL_METHOD
		    Address("\(faucet.addressString())")
		    "lock_fee"
		    Decimal("10");

		# Calling the "free" method on the faucet component which is the method responsible for dispensing
		# XRD from the faucet.
		CALL_METHOD
		    Address("\(faucet.addressString())")
		    "free";

		# Depositing all of the XRD dispensed from the faucet into our account component.
		CALL_METHOD
		    Address("\(componentAddress.address)")
		    "try_deposit_batch_or_abort"
		    Expression("ENTIRE_WORKTOP");

		"""
		let instructions = try Instructions.fromString(string: raw, blobs: [], networkId: networkID.rawValue)
		return TransactionManifest(
			instructions: instructions,
			blobs: []
		)
	}

	public static func manifestForCreateNonFungibleToken(
		account: AccountAddress,
		network: NetworkID
	) throws -> TransactionManifest {
		let raw = """
		\(noFungibleWithInitialSupplyInstruction())
		CALL_METHOD
		    Address("\(account.address)")
		    "deposit_batch"
		    Expression("ENTIRE_WORKTOP")
		;
		"""

		return try .init(instructions: .fromString(string: raw, blobs: [], networkId: network.rawValue), blobs: [])
	}

	public static func manifestForCreateMultipleNonFungibleTokens(
		account: AccountAddress,
		network: NetworkID
	) throws -> TransactionManifest {
		let instructions = [String](repeating: noFungibleWithInitialSupplyInstruction(), count: 10).joined(separator: "\n")
		let raw = """
		 \(instructions)
		CALL_METHOD
		    Address("\(account.address)")
		    "deposit_batch"
		    Expression("ENTIRE_WORKTOP")
		;
		"""

		return try .init(instructions: .fromString(string: raw, blobs: [], networkId: network.rawValue), blobs: [])
	}

	public static func manifestForCreateFungibleToken(
		account: AccountAddress,
		network: NetworkID
	) throws -> TransactionManifest {
		let raw = """
		\(fungibleWithInitialSupplyInstruction())

		                # Depositing the entirety of the initial supply of the newly created resource into our account
		                # component.
		                CALL_METHOD
		                    Address("\(account.address)")
		                    "deposit_batch"
		                    Expression("ENTIRE_WORKTOP");
		"""

		return try .init(instructions: .fromString(string: raw, blobs: [], networkId: network.rawValue), blobs: [])
	}

	public static func manifestForCreateMultipleFungibleTokens(
		account: AccountAddress,
		network: NetworkID
	) throws -> TransactionManifest {
		let instructions = [String](repeating: fungibleWithInitialSupplyInstruction(), count: 20).joined(separator: "\n")
		let raw = """
		 \(instructions)
		CALL_METHOD
		    Address("\(account.address)")
		    "deposit_batch"
		    Expression("ENTIRE_WORKTOP")
		;
		"""

		return try .init(instructions: .fromString(string: raw, blobs: [], networkId: network.rawValue), blobs: [])
	}

	private func faucetAddress(networkID: NetworkID) -> EngineToolkitUniFFI.Address {
		utilsKnownAddresses(networkId: networkID.rawValue).componentAddresses.faucet
	}

	private static func fungibleWithInitialSupplyInstruction() -> String {
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

	private static func noFungibleWithInitialSupplyInstruction() -> String {
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

extension Instruction {
	public static func lockFeeCall(
		address: Address,
		fee: String = "10"
	) throws -> Instruction {
		try .callMethod(address: .init(address: address.address), methodName: "lock_fee", args: .decimalValue(value: .init(value: fee)))
	}
}
