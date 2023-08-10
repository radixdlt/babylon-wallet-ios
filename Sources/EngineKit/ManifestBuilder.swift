import EngineToolkit
import Prelude

// MARK: - Result Builder
extension ManifestBuilder {
	public static let faucetLockFee = flip(faucetLockFee)
	public static let faucetFreeXrd = flip(faucetFreeXrd)
	public static let accountTryDepositBatchOrAbort = flip(accountTryDepositBatchOrAbort)
	public static let withdrawAmount = flip(withdrawAmount)
	public static let withdrawTokens = flip(withdrawTokens)
	public static let takeFromWorktop = flip(takeFromWorktop)
	public static let accountTryDepositOrAbort = flip(accountTryDepositOrAbort)
	public static let takeNonFungiblesFromWorktop = flip(takeNonFungiblesFromWorktop)

	@resultBuilder
	public enum InstructionsChain {
		public typealias Instructions = [Instruction]
		public typealias Instruction = (ManifestBuilder) throws -> ManifestBuilder

		public static func buildBlock(_ components: Instructions...) -> Instructions {
			Array(components.joined())
		}

		public static func buildArray(_ components: [Instructions]) -> Instructions {
			Array(components.joined())
		}

		public static func buildExpression(_ expression: @escaping Instruction) -> Instructions {
			[expression]
		}

		public static func buildOptional(_ component: Instructions?) -> Instructions {
			component ?? []
		}
	}

	public static func make(@InstructionsChain _ content: () throws -> InstructionsChain.Instructions) throws -> ManifestBuilder {
		var builder = ManifestBuilder()
		try content().forEach {
			builder = try $0(builder)
		}
		return builder
	}
}

// MARK: - Helper build functions
extension ManifestBuilder {
	public func withdrawAmount(from entity: Address, resource: ResourceAddress, amount: BigDecimal) throws -> EngineToolkit.ManifestBuilder {
		try callMethod(
			address: entity.wrapped(),
			methodName: "withdraw",
			args: [.addressValue(value: resource.wrapped()), .decimalValue(value: amount.intoEngine())]
		)
	}

	public func withdrawTokens(from entity: Address, resource: ResourceAddress, tokens: [NonFungibleLocalId]) throws -> EngineToolkit.ManifestBuilder {
		try callMethod(
			address: entity.wrapped(),
			methodName: "withdraw",
			args: [
				.addressValue(value: resource.wrapped()),
				.arrayValue(
					elementValueKind: .nonFungibleLocalIdValue,
					elements: tokens.map { .nonFungibleLocalIdValue(value: $0) }
				),
			]
		)
	}
}

// MARK: - Predifined manifest builders
extension ManifestBuilder {
	public static func manifestForFaucett(
		includeLockFeeInstruction: Bool,
		networkID: NetworkID,
		componentAddress: Address
	) throws -> TransactionManifest {
		try Self.make {
			if includeLockFeeInstruction {
				faucetLockFee
			}
			faucetFreeXrd
			try accountTryDepositBatchOrAbort(componentAddress.intoEngine(), nil)
		}
		.build(networkId: networkID.rawValue)
	}
}

func flip<A, T>(_ f: @escaping (A) -> () throws -> T) -> (A) throws -> T {
	{ a in
		try f(a)()
	}
}

func flip<A, B, T>(_ f: @escaping (A) -> (B) throws -> T) -> (B) -> (A) throws -> T {
	{ b in
		{ a in
			try f(a)(b)
		}
	}
}

func flip<A, B, C, T>(_ f: @escaping (A) -> (B, C) throws -> T) -> (B, C) -> (A) throws -> T {
	{ b, c in
		{ a in
			try f(a)(b, c)
		}
	}
}

func flip<A, B, C, D, T>(_ f: @escaping (A) -> (B, C, D) throws -> T) -> (B, C, D) -> (A) throws -> T {
	{ b, c, d in
		{ a in
			try f(a)(b, c, d)
		}
	}
}

extension ManifestBuilderBucket {
	public static var unique: ManifestBuilderBucket {
		.init(name: UUID().uuidString)
	}
}

extension SpecificAddress {
	func wrapped() throws -> ManifestBuilderAddress {
		try .static(value: self.intoEngine())
	}
}

extension BigDecimal {
	public func intoEngine() throws -> EngineKit.Decimal {
		try .init(value: toString())
	}
}

extension TransactionManifest {
	public func withInstructionAdded(_ instruction: Instruction, at index: Int) throws -> TransactionManifest {
		try .init(
			instructions: instructions().withInstructionAdded(instruction, at: index),
			blobs: blobs()
		)
	}

	public func withLockFeeCallMethodAdded(
		address: Address,
		fee: BigDecimal = .temporaryStandardFee
	) throws -> TransactionManifest {
		try modify(modifications: TransactionManifestModifications(
			addAccessControllerProofs: [],
			addLockFee: .init(
				accountAddress: address.intoEngine(),
				amount: fee.intoEngine()
			),
			addAssertions: []
		))
	}
}

// MARK: - Custom Manifests
extension TransactionManifest {
	public static func manifestForFaucet(
		includeLockFeeInstruction: Bool,
		networkID: NetworkID,
		componentAddress: Address
	) throws -> TransactionManifest {
		try EngineToolkit.ManifestBuilder()
			.faucetLockFee()
			.faucetFreeXrd()
			.accountTryDepositBatchOrAbort(accountAddress: componentAddress.intoEngine(), authorizedDepositorBadge: nil)
			.build(networkId: networkID.rawValue)
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
		fee: BigDecimal = .temporaryStandardFee
	) throws -> Instructions {
		try withInstructionAdded(
			.lockFeeCall(address: address, fee: fee),
			at: 0
		)
	}

	static func faucetAddress(networkID: NetworkID) -> EngineToolkit.Address {
		knownAddresses(networkId: networkID.rawValue).componentAddresses.faucet
	}

	static func from(rawInstructions: [String], network: NetworkID) throws -> Instructions {
		try .fromString(string: rawInstructions.joined(separator: "\n"), networkId: network.rawValue)
	}

	static func createFungibleToken(
		account: AccountAddress,
		network: NetworkID
	) throws -> Instructions {
		let instructions: [String] = [
			Instruction.fungibleWithInitialSupplyInstruction(),
			Instruction.tryDepositBatchOrAbort(componentAddress: account.asGeneral()),
		]
		return try .from(rawInstructions: instructions, network: network).withLockFeeCallMethodAdded(address: account.asGeneral())
	}

	static func createMultipleFungibleTokens(
		account: AccountAddress,
		network: NetworkID
	) throws -> Instructions {
		let instructions = [String](repeating: Instruction.fungibleWithInitialSupplyInstruction(), count: 20) + [Instruction.tryDepositBatchOrAbort(componentAddress: account.asGeneral())]
		return try .from(rawInstructions: instructions, network: network).withLockFeeCallMethodAdded(address: account.asGeneral())
	}

	static func createMultipleNonFungibleTokens(
		account: AccountAddress,
		network: NetworkID
	) throws -> Instructions {
		let instructions = [String](repeating: Instruction.noFungibleWithInitialSupplyInstruction(), count: 10) + [Instruction.tryDepositBatchOrAbort(componentAddress: account.asGeneral())]
		return try .from(rawInstructions: instructions, network: network).withLockFeeCallMethodAdded(address: account.asGeneral())
	}

	static func createNonFungibleToken(
		account: AccountAddress,
		network: NetworkID
	) throws -> Instructions {
		let instructions: [String] = [
			Instruction.noFungibleWithInitialSupplyInstruction(),
			Instruction.tryDepositBatchOrAbort(componentAddress: account.asGeneral()),
		]
		return try .from(rawInstructions: instructions, network: network).withLockFeeCallMethodAdded(address: account.asGeneral())
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
			return try instructions.withLockFeeCallMethodAdded(address: faucet.asSpecific())
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
		fee: BigDecimal
	) throws -> Instruction {
		try .callMethod(address: .static(value: .init(address: address.address)), methodName: "lock_fee", args: .tupleValue(fields: [.decimalValue(value: .init(value: fee.toString()))]))
	}

	static func depositBatch(account: AccountAddress) -> String {
		"""
		CALL_METHOD
		    Address("\(account.address)")
		    "deposit_batch"
		    Expression("ENTIRE_WORKTOP");
		"""
	}

	static func free(address: EngineToolkit.Address) -> String {
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
		    # Owner role - This gets metadata permissions, and is the default for other permissions
		    # Can set as Enum<OwnerRole::Fixed>(access_rule)  or Enum<OwnerRole::Updatable>(access_rule)
		    Enum<OwnerRole::None>()
		    true             # Whether the engine should track supply (avoid for massively parallelizable tokens)
		    18u8             # Divisibility (between 0u8 and 18u8)
		    Decimal("100") # Initial supply
		    Tuple(
		        Some(         # Mint Roles (if None: defaults to DenyAll, DenyAll)
		            Tuple(
		                Some(Enum<AccessRule::AllowAll>()),  # Minter (if None: defaults to Owner)
		                Some(Enum<AccessRule::DenyAll>())    # Minter Updater (if None: defaults to Owner)
		            )
		        ),
		        None,        # Burn Roles (if None: defaults to DenyAll, DenyAll)
		        None,        # Freeze Roles (if None: defaults to DenyAll, DenyAll)
		        None,        # Recall Roles (if None: defaults to DenyAll, DenyAll)
		        None,        # Withdraw Roles (if None: defaults to AllowAll, DenyAll)
		        None         # Deposit Roles (if None: defaults to AllowAll, DenyAll)
		    )
		    Tuple(                                                                   # Metadata initialization
		        Map<String, Tuple>(                                                  # Initial metadata values
		            "name" => Tuple(
		                Some(Enum<Metadata::String>("MyResource")),    # Resource Name
		                true                                                         # Locked
		            ),
		            "symbol" => Tuple(
		                Some(Enum<Metadata::String>("VIP")),
		                true
		            ),
		            "description" => Tuple(
		                Some(Enum<Metadata::String>("A very innovative and important resource")),
		                true
		            ),
		            "icon_url" => Tuple(
		              Some(Enum<Metadata::String>("https://i.imgur.com/9YQ9Z0x.png")),
		              true
		            )
		        ),
		        Map<String, Enum>(                                                   # Metadata roles
		            "metadata_setter" => Some(Enum<AccessRule::AllowAll>()),         # Metadata setter role
		            "metadata_setter_updater" => None,                               # Metadata setter updater role as None defaults to OWNER
		            "metadata_locker" => Some(Enum<AccessRule::DenyAll>()),          # Metadata locker role
		            "metadata_locker_updater" => None                                # Metadata locker updater role as None defaults to OWNER
		        )
		    )
		    None;             # No Address Reservation
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
		case .secp256k1: return "0u8"
		case .ed25519: return "1u8"
		}
	}

	func bytes() throws -> [UInt8] {
		switch self {
		case let .secp256k1(value), let .ed25519(value):
			return value
		}
	}
}
