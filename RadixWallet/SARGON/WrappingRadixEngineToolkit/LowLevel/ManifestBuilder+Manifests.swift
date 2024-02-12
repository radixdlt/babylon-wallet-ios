

extension ManifestBuilder {
	public static func withdrawAmount(
		_ from: RETAddress,
		_ resourceAddress: RETAddress,
		_ amount: RETDecimal
	) -> ManifestBuilder.InstructionsChain.Instruction {
		panic()
	}

	public static func withdrawTokens(
		fungible: ResourceAddress,
		nonFungibleIDs: [NonFungibleLocalId],
		fromOwner: AccountAddress
	) -> ManifestBuilder.InstructionsChain.Instruction {
		panic()
	}

	public static func takeFromWorktop(
		_ address: RETAddress,
		_ amount: RETDecimal,
		_ bucket: ManifestBuilderBucket
	) -> ManifestBuilder.InstructionsChain.Instruction {
		panic()
	}

	public static func accountTryDepositOrAbort(
		_ address: RETAddress,
		_ bucket: ManifestBuilderBucket,
		_ authorizedDepositorBadge: ResourceOrNonFungible?
	) -> ManifestBuilder.InstructionsChain.Instruction {
		panic()
	}

	public static func accountDeposit(
		_ recipientAddress: RETAddress,
		_ bucket: ManifestBuilderBucket
	) -> ManifestBuilder.InstructionsChain.Instruction {
		panic()
	}

	///	= flip(takeNonFungiblesFromWorktop)
	public static func takeNonFungiblesFromWorktop(
		_ resourceAddress: RETAddress,
		_ localIds: [NonFungibleLocalId],
		_ bucket: ManifestBuilderBucket
	) -> ManifestBuilder.InstructionsChain.Instruction {
		panic()
	}

	public static func accountWithdrawNonFungibles(
		_ account: RETAddress,
		_ resourceAddress: RETAddress,
		_ ids: [NonFungibleLocalId]
	) -> ManifestBuilder.InstructionsChain.Instruction {
		panic()
	}

	public func createFungibleResourceManager(
		ownerRole: OwnerRole,
		trackTotalSupply: Bool,
		divisibility: UInt8,
		initialSupply: RETDecimal,
		resourceRoles: FungibleResourceRoles,
		metadata: MetadataModuleConfig,
		addressReservation: ManifestBuilderAddressReservation?
	) -> ManifestBuilder {
		panic()
	}

	public static func createFungibleResourceManager(
		_ ownerRole: OwnerRole,
		_ trackTotalSupply: Bool,
		_ divisibility: UInt8,
		_ initialSupply: RETDecimal,
		_ resourceRoles: FungibleResourceRoles,
		_ metadata: MetadataModuleConfig,
		_ addressReservation: ManifestBuilderAddressReservation?
	) -> ManifestBuilder.InstructionsChain.Instruction {
		panic()
	}

	public static func validatorClaimXrd(
		_ validatorAddress: RETAddress,
		_ bucket: ManifestBuilderBucket
	) -> ManifestBuilder.InstructionsChain.Instruction {
		panic()
	}

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

		public static func buildEither(first component: Instructions) -> Instructions {
			component
		}

		public static func buildEither(second component: Instructions) -> Instructions {
			component
		}
	}

	/// A result builder extension on ManifestBuilder to allow easier building of the manifests when there is additional logic required to compute the manifest.
	/// Examples:
	/// - Building a manifest with dynamic number of instructions, requiring a `for-loop`
	/// - Building a manifest that has conditional logic to add certain instructions, requiring to use `if-else` statements.
	///
	/// If the manifest you are trying to build does not require additional logic, simply use the `ManifestBuilder()`.
	public static func make(@InstructionsChain _ content: () throws -> InstructionsChain.Instructions) throws -> ManifestBuilder {
		var builder = ManifestBuilder()
		// Collect all partial instructions to be built
		for item in try content() {
			// Build each instruction by updating the builder
			builder = try item(builder)
		}
		return builder
	}

	public static func make(@InstructionsChain _ content: () async throws -> InstructionsChain.Instructions) async throws -> ManifestBuilder {
		var builder = ManifestBuilder()
		// Collect all partial instructions to be built
		for item in try await content() {
			// Build each instruction by updating the builder
			builder = try item(builder)
		}
		return builder
	}
}

/// Flips the argument order of a five-argument curried function.
///
/// - Parameter function: A five-argument, curried function.
/// - Returns: A curried function with its first two arguments flipped.
public func flip<A, B, C, D, E, F, G, H, I>(_ function: @escaping (A) -> (B, C, D, E, F, G, H) throws -> I)
	-> (B, C, D, E, F, G, H) -> (A) throws -> I
{
	{ (b: B, c: C, d: D, e: E, f: F, g: G, h: H) -> (A) throws -> I in
		{ (a: A) throws -> I in
			try function(a)(b, c, d, e, f, g, h)
		}
	}
}

extension ManifestBuilder {
	public func setOwnerKeys(
		from entity: Address,
		ownerKeyHashes: [RETPublicKeyHash]
	) throws -> ManifestBuilder {
		try metadataSet(
			address: entity.intoEngine(),
			key: "owner_keys",
			value: .publicKeyHashArrayValue(value: ownerKeyHashes)
		)
	}

	public func setAccountType(
		from entity: Address,
		type: String
	) throws -> ManifestBuilder {
		try metadataSet(address: entity.intoEngine(), key: "account_type", value: .stringValue(value: type))
	}

	public func metadataSet(
		address: RETAddress,
		key: String,
		value: MetadataValue
	) throws -> ManifestBuilder {
		panic()
	}
}

extension ManifestBuilderBucket {
	public static var unique: ManifestBuilderBucket {
		panic()
	}
}

extension SpecificAddress {
	public func intoManifestBuilderAddress() throws -> ManifestBuilderAddress {
		try .static(value: self.intoEngine())
	}
}

extension TransactionManifest {
	public func withInstructionAdded(_ instruction: Instruction, at index: Int) throws -> TransactionManifest {
		try .init(
			instructions: instructions().withInstructionAdded(instruction, at: index),
			blobs: blobs()
		)
	}
}

extension Instructions {
	public func withInstructionAdded(_ instruction: Instruction, at index: Int) throws -> Instructions {
		var instructionList = self.instructionsList()
		instructionList.insert(instruction, at: index)
		return try .fromInstructions(instructions: instructionList, networkId: self.networkId())
	}
}

// MARK: Manifests for testing
extension ManifestBuilder {
	public static func manifestForCreateNonFungibleToken(
		account: AccountAddress,
		networkID: NetworkID
	) throws -> TransactionManifest {
		let instructions = try Instructions.fromString(
			string: createNonFungibleTokensRawManifest(account: account),
			networkId: networkID.rawValue
		)

		return TransactionManifest(instructions: instructions, blobs: [])
	}

	public static func manifestForCreateMultipleNonFungibleTokens(
		account: AccountAddress,
		networkID: NetworkID
	) throws -> TransactionManifest {
		let instructions = try Instructions.fromString(
			string: createNonFungibleTokensRawManifest(account: account, nrOfTokens: 15),
			networkId: networkID.rawValue
		)
		return TransactionManifest(instructions: instructions, blobs: [])
	}
}

extension ManifestBuilder {
	static var createSmallNonFungbileResourceRawInstruction: String {
		"""
						CREATE_NON_FUNGIBLE_RESOURCE_WITH_INITIAL_SUPPLY
							Enum<0u8>()
							Enum<1u8>()
							true
							Enum<0u8>(
							Enum<0u8>(
							Tuple(
							Array<Enum>(
							Enum<14u8>(
							Array<Enum>(
							Enum<0u8>(
							12u8
							),
							Enum<0u8>(
							12u8
							),
							Enum<0u8>(
							198u8
							),
							Enum<0u8>(
							10u8
							)
							)
							)
							),
							Array<Tuple>(
							Tuple(
							Enum<1u8>(
							"MetadataStandardNonFungibleData"
							),
							Enum<1u8>(
							Enum<0u8>(
							Array<String>(
							"name",
							"description",
							"key_image_url",
							"arbitrary_coolness_rating"
							)
							)
							)
							)
							),
							Array<Enum>(

							Enum<0u8>()
							)
							)
							),
							Enum<1u8>(
							0u64
							),
							Array<String>()
							)
							Map<NonFungibleLocalId,    Tuple>(
							NonFungibleLocalId("#0#")    =>    Tuple(
							Tuple(
							"URL    With    white    space",
							"URL    with    white    space",
							"https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/KL    Haze-medium.jpg",
							45u64
							)
							)
							)
							Tuple(
							Enum<0u8>(),
							Enum<0u8>(),
							Enum<0u8>(),
							Enum<0u8>(),
							Enum<0u8>(),
							Enum<0u8>(),
							Enum<0u8>()
							)
							Tuple(
							Map<String,    Tuple>(
							"description"    =>    Tuple(
							Enum<1u8>(
							Enum<0u8>(
							"A    very    innovative    and    important    resource"
							)
							),
							true
							),
							"icon_url"    =>    Tuple(
							Enum<1u8>(
							Enum<13u8>(
							"https://upload.wikimedia.org/wikipedia/commons/b/be/VeKings.png"
							)
							),
							true
							),
							"info_url"    =>    Tuple(
							Enum<1u8>(
							Enum<13u8>(
							"https://developers.radixdlt.com/ecosystem"
							)
							),
							true
							),
							"name"    =>    Tuple(
							Enum<1u8>(
							Enum<0u8>(
							"SandboxNFT"
							)
							),
							true
							),
							"tags"    =>    Tuple(
							Enum<1u8>(
							Enum<128u8>(
							Array<String>(
							"collection",
							"sandbox",
							"example-tag"
							)
							)
							),
							true
							)
							),
							Map<String,    Enum>()
							)
							Enum<0u8>();
		"""
	}

	static var createMultipleIdsNonFungibleResourceRawInstruction: String {
		"""
				CREATE_NON_FUNGIBLE_RESOURCE_WITH_INITIAL_SUPPLY
					Enum<0u8>()
					Enum<1u8>()
					true
					Enum<0u8>(
					Enum<0u8>(
					Tuple(
					Array<Enum>(
					Enum<14u8>(
					Array<Enum>(
					Enum<0u8>(
					12u8
					),
					Enum<0u8>(
					12u8
					),
					Enum<0u8>(
					198u8
					),
					Enum<0u8>(
					10u8
					)
					)
					)
					),
					Array<Tuple>(
					Tuple(
					Enum<1u8>(
					"MetadataStandardNonFungibleData"
					),
					Enum<1u8>(
					Enum<0u8>(
					Array<String>(
					"name",
					"description",
					"key_image_url",
					"arbitrary_coolness_rating"
					)
					)
					)
					)
					),
					Array<Enum>(

					Enum<0u8>()
					)
					)
					),
					Enum<1u8>(
					0u64
					),
					Array<String>()
					)
					Map<NonFungibleLocalId,    Tuple>(
					NonFungibleLocalId("#0#")    =>    Tuple(
					Tuple(
					"URL    With    white    space",
					"URL    with    white    space",
					"https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/KL    Haze-medium.jpg",
					45u64
					)
					),
					NonFungibleLocalId("#1#")    =>    Tuple(
					Tuple(
					"Filling    Station    Breakfast    Large",
					"Filling    Station    Breakfast    Large",
					"https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/Filling+Station+Breakfast-large.jpg",
					45u64
					)
					),
					NonFungibleLocalId("#2#")    =>    Tuple(
					Tuple(
					"Filling    Station    Breakfast    Medium",
					"Filling    Station    Breakfast    Medium",
					"https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/Filling+Station+Breakfast-medium.jpg",
					45u64
					)
					),
					NonFungibleLocalId("#3#")    =>    Tuple(
					Tuple(
					"Filling    Station    Breakfast    Small",
					"Filling    Station    Breakfast    Small",
					"https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/Filling+Station+Breakfast-small.jpg",
					45u64
					)
					),
					NonFungibleLocalId("#4#")    =>    Tuple(
					Tuple(
					"Frame    6    Large",
					"Frame    6    Large",
					"https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/Frame+6-large.png",
					45u64
					)
					),
					NonFungibleLocalId("#5#")    =>    Tuple(
					Tuple(
					"Frame    6    Medium",
					"Frame    6    Medium",
					"https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/Frame+6-medium.png",
					45u64
					)
					),
					NonFungibleLocalId("#6#")    =>    Tuple(
					Tuple(
					"Frame    6    Small",
					"Frame    6    Small",
					"https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/Frame+6-small.png",
					45u64
					)
					),
					NonFungibleLocalId("#7#")    =>    Tuple(
					Tuple(
					"Kway    Teow    Large",
					"Kway    Teow    Large",
					"https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/Fried+Kway+Teow-large.jpg",
					45u64
					)
					),
					NonFungibleLocalId("#8#")    =>    Tuple(
					Tuple(
					"Kway    Teow    Medium",
					"Kway    Teow    Medium",
					"https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/Fried+Kway+Teow-medium.jpg",
					45u64
					)
					),
					NonFungibleLocalId("#9#")    =>    Tuple(
					Tuple(
					"Kway    Teow    Small",
					"Kway    Teow    Small",
					"https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/Fried+Kway+Teow-small.jpg",
					45u64
					)
					),
					NonFungibleLocalId("#10#")    =>    Tuple(
					Tuple(
					"ICON    Transparency    PNG",
					"ICON    Transparency    PNG",
					"https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/ICON-transparency.png",
					45u64
					)
					),
					NonFungibleLocalId("#11#")    =>    Tuple(
					Tuple(
					"KL    Haze    Large",
					"KL    Haze    Large",
					"https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/KL+Haze-large.jpg",
					45u64
					)
					),
					NonFungibleLocalId("#12#")    =>    Tuple(
					Tuple(
					"KL    Haze    Medium",
					"KL    Haze    Medium",
					"https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/KL+Haze-medium.jpg",
					45u64
					)
					),
					NonFungibleLocalId("#13#")    =>    Tuple(
					Tuple(

					"KL    Haze    Small",
					"KL    Haze    Small",
					"https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/KL+Haze-small.jpg",
					45u64
					)
					),
					NonFungibleLocalId("#14#")    =>    Tuple(
					Tuple(
					"modern    kunst    musem    pano    2",
					"modern    kunst    musem    pano    2",
					"https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/modern_kunst_museum_pano-2.jpg",
					45u64
					)
					),
					NonFungibleLocalId("#15#")    =>    Tuple(
					Tuple(
					"modern    kunst    musem    pano    3",
					"modern    kunst    musem    pano    3",
					"https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/modern_kunst_museum_pano-3.jpg",
					45u64
					)
					),
					NonFungibleLocalId("#16#")    =>    Tuple(
					Tuple(
					"modern    kunst    musem    pano    0",
					"modern    kunst    musem    pano    0",
					"https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/modern_kunst_museum_pano.jpg",
					45u64
					)
					),
				NonFungibleLocalId("#20#")    =>    Tuple(
					Tuple(
					"modern    kunst    musem    pano    3",
					"modern    kunst    musem    pano    3",
					"https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/modern_kunst_museum_pano-3.jpg",
					45u64
					)
					),
				NonFungibleLocalId("#21#")    =>    Tuple(
					Tuple(
					"modern    kunst    musem    pano    3",
					"modern    kunst    musem    pano    3",
					"https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/modern_kunst_museum_pano-3.jpg",
					45u64
					)
					),
				NonFungibleLocalId("#22#")    =>    Tuple(
					Tuple(
					"modern    kunst    musem    pano    3",
					"modern    kunst    musem    pano    3",
					"https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/modern_kunst_museum_pano-3.jpg",
					45u64
					)
					),
				NonFungibleLocalId("#23#")    =>    Tuple(
					Tuple(
					"modern    kunst    musem    pano    3",
					"modern    kunst    musem    pano    3",
					"https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/modern_kunst_museum_pano-3.jpg",
					45u64
					)
					),
				NonFungibleLocalId("#24#")    =>    Tuple(
					Tuple(
					"modern    kunst    musem    pano    3",
					"modern    kunst    musem    pano    3",
					"https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/modern_kunst_museum_pano-3.jpg",
					45u64
					)
					),
				NonFungibleLocalId("#25#")    =>    Tuple(
					Tuple(
					"modern    kunst    musem    pano    3",
					"modern    kunst    musem    pano    3",
					"https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/modern_kunst_museum_pano-3.jpg",
					45u64
					)
					),
				NonFungibleLocalId("#26#")    =>    Tuple(
					Tuple(
					"modern    kunst    musem    pano    3",
					"modern    kunst    musem    pano    3",
					"https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/modern_kunst_museum_pano-3.jpg",
					45u64
					)
					),
				NonFungibleLocalId("#27#")    =>    Tuple(
					Tuple(
					"modern    kunst    musem    pano    3",
					"modern    kunst    musem    pano    3",
					"https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/modern_kunst_museum_pano-3.jpg",
					45u64
					)
					),
				NonFungibleLocalId("#28#")    =>    Tuple(
					Tuple(
					"modern    kunst    musem    pano    3",
					"modern    kunst    musem    pano    3",
					"https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/modern_kunst_museum_pano-3.jpg",
					45u64
					)
					),
				NonFungibleLocalId("#29#")    =>    Tuple(
					Tuple(
					"modern    kunst    musem    pano    3",
					"modern    kunst    musem    pano    3",
					"https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/modern_kunst_museum_pano-3.jpg",
					45u64
					)
					),
				NonFungibleLocalId("#30#")    =>    Tuple(
					Tuple(
					"modern    kunst    musem    pano    3",
					"modern    kunst    musem    pano    3",
					"https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/modern_kunst_museum_pano-3.jpg",
					45u64
					)
					),
				NonFungibleLocalId("#31#")    =>    Tuple(
					Tuple(
					"modern    kunst    musem    pano    3",
					"modern    kunst    musem    pano    3",
					"https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/modern_kunst_museum_pano-3.jpg",
					45u64
					)
					),
				NonFungibleLocalId("#32#")    =>    Tuple(
					Tuple(
					"modern    kunst    musem    pano    3",
					"modern    kunst    musem    pano    3",
					"https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/modern_kunst_museum_pano-3.jpg",
					45u64
					)
					),
				NonFungibleLocalId("#33#")    =>    Tuple(
					Tuple(
					"modern    kunst    musem    pano    3",
					"modern    kunst    musem    pano    3",
					"https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/modern_kunst_museum_pano-3.jpg",
					45u64
					)
					),
				NonFungibleLocalId("#34#")    =>    Tuple(
					Tuple(
					"modern    kunst    musem    pano    3",
					"modern    kunst    musem    pano    3",
					"https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/modern_kunst_museum_pano-3.jpg",
					45u64
					)
					),
				NonFungibleLocalId("#35#")    =>    Tuple(
					Tuple(
					"modern    kunst    musem    pano    3",
					"modern    kunst    musem    pano    3",
					"https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/modern_kunst_museum_pano-3.jpg",
					45u64
					)
					),
				NonFungibleLocalId("#36#")    =>    Tuple(
					Tuple(
					"modern    kunst    musem    pano    3",
					"modern    kunst    musem    pano    3",
					"https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/modern_kunst_museum_pano-3.jpg",
					45u64
					)
					),
				NonFungibleLocalId("#37#")    =>    Tuple(
					Tuple(
					"modern    kunst    musem    pano    3",
					"modern    kunst    musem    pano    3",
					"https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/modern_kunst_museum_pano-3.jpg",
					45u64
					)
					),
				NonFungibleLocalId("#38#")    =>    Tuple(
					Tuple(
					"modern    kunst    musem    pano    3",
					"modern    kunst    musem    pano    3",
					"https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/modern_kunst_museum_pano-3.jpg",
					45u64
					)
					),
				NonFungibleLocalId("#39#")    =>    Tuple(
					Tuple(
					"modern    kunst    musem    pano    3",
					"modern    kunst    musem    pano    3",
					"https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/modern_kunst_museum_pano-3.jpg",
					45u64
					)
					),
				NonFungibleLocalId("#40#")    =>    Tuple(
					Tuple(
					"modern    kunst    musem    pano    3",
					"modern    kunst    musem    pano    3",
					"https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/modern_kunst_museum_pano-3.jpg",
					45u64
					)
					),
				NonFungibleLocalId("#41#")    =>    Tuple(
					Tuple(
					"modern    kunst    musem    pano    3",
					"modern    kunst    musem    pano    3",
					"https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/modern_kunst_museum_pano-3.jpg",
					45u64
					)
					),
				NonFungibleLocalId("#42#")    =>    Tuple(
					Tuple(
					"modern    kunst    musem    pano    3",
					"modern    kunst    musem    pano    3",
					"https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/modern_kunst_museum_pano-3.jpg",
					45u64
					)
					),
				NonFungibleLocalId("#43#")    =>    Tuple(
					Tuple(
					"modern    kunst    musem    pano    3",
					"modern    kunst    musem    pano    3",
					"https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/modern_kunst_museum_pano-3.jpg",
					45u64
					)
					),
				NonFungibleLocalId("#44#")    =>    Tuple(
					Tuple(
					"modern    kunst    musem    pano    3",
					"modern    kunst    musem    pano    3",
					"https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/modern_kunst_museum_pano-3.jpg",
					45u64
					)
					),
				NonFungibleLocalId("#45#")    =>    Tuple(
					Tuple(
					"modern    kunst    musem    pano    3",
					"modern    kunst    musem    pano    3",
					"https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/modern_kunst_museum_pano-3.jpg",
					45u64
					)
					),
				NonFungibleLocalId("#46#")    =>    Tuple(
					Tuple(
					"modern    kunst    musem    pano    3",
					"modern    kunst    musem    pano    3",
					"https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/modern_kunst_museum_pano-3.jpg",
					45u64
					)
					),
				NonFungibleLocalId("#47#")    =>    Tuple(
					Tuple(
					"modern    kunst    musem    pano    3",
					"modern    kunst    musem    pano    3",
					"https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/modern_kunst_museum_pano-3.jpg",
					45u64
					)
					),
				NonFungibleLocalId("#48#")    =>    Tuple(
					Tuple(
					"modern    kunst    musem    pano    3",
					"modern    kunst    musem    pano    3",
					"https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/modern_kunst_museum_pano-3.jpg",
					45u64
					)
					),
				NonFungibleLocalId("#49#")    =>    Tuple(
					Tuple(
					"modern    kunst    musem    pano    3",
					"modern    kunst    musem    pano    3",
					"https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/modern_kunst_museum_pano-3.jpg",
					45u64
					)
					),
				NonFungibleLocalId("#50#")    =>    Tuple(
					Tuple(
					"modern    kunst    musem    pano    3",
					"modern    kunst    musem    pano    3",
					"https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/modern_kunst_museum_pano-3.jpg",
					45u64
					)
					),
				NonFungibleLocalId("#51#")    =>    Tuple(
					Tuple(
					"modern    kunst    musem    pano    3",
					"modern    kunst    musem    pano    3",
					"https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/modern_kunst_museum_pano-3.jpg",
					45u64
					)
					),
				NonFungibleLocalId("#52#")    =>    Tuple(
					Tuple(
					"modern    kunst    musem    pano    3",
					"modern    kunst    musem    pano    3",
					"https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/modern_kunst_museum_pano-3.jpg",
					45u64
					)
					),
				NonFungibleLocalId("#53#")    =>    Tuple(
					Tuple(
					"modern    kunst    musem    pano    3",
					"modern    kunst    musem    pano    3",
					"https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/modern_kunst_museum_pano-3.jpg",
					45u64
					)
					),
				NonFungibleLocalId("#54#")    =>    Tuple(
					Tuple(
					"modern    kunst    musem    pano    3",
					"modern    kunst    musem    pano    3",
					"https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/modern_kunst_museum_pano-3.jpg",
					45u64
					)
					),
				NonFungibleLocalId("#55#")    =>    Tuple(
					Tuple(
					"modern    kunst    musem    pano    3",
					"modern    kunst    musem    pano    3",
					"https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/modern_kunst_museum_pano-3.jpg",
					45u64
					)
					),
				NonFungibleLocalId("#56#")    =>    Tuple(
					Tuple(
					"modern    kunst    musem    pano    3",
					"modern    kunst    musem    pano    3",
					"https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/modern_kunst_museum_pano-3.jpg",
					45u64
					)
					),
				NonFungibleLocalId("#57#")    =>    Tuple(
					Tuple(
					"modern    kunst    musem    pano    3",
					"modern    kunst    musem    pano    3",
					"https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/modern_kunst_museum_pano-3.jpg",
					45u64
					)
					),
				NonFungibleLocalId("#58#")    =>    Tuple(
					Tuple(
					"modern    kunst    musem    pano    3",
					"modern    kunst    musem    pano    3",
					"https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/modern_kunst_museum_pano-3.jpg",
					45u64
					)
					),
				NonFungibleLocalId("#59#")    =>    Tuple(
					Tuple(
					"modern    kunst    musem    pano    3",
					"modern    kunst    musem    pano    3",
					"https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/modern_kunst_museum_pano-3.jpg",
					45u64
					)
					),
					NonFungibleLocalId("#17#")    =>    Tuple(
					Tuple(
					"Scryptonaut    Patch    SVG",
					"Scryptonaut    Patch    SVG",
					"https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/scryptonaut_patch.svg",
					45u64
					)
					)
					)
					Tuple(
					Enum<0u8>(),
					Enum<0u8>(),
					Enum<0u8>(),
					Enum<0u8>(),
					Enum<0u8>(),
					Enum<0u8>(),
					Enum<0u8>()
					)
					Tuple(
					Map<String,    Tuple>(
					"description"    =>    Tuple(
					Enum<1u8>(
					Enum<0u8>(
					"A    very    innovative    and    important    resource"
					)
					),
					true
					),
					"icon_url"    =>    Tuple(
					Enum<1u8>(
					Enum<13u8>(
					"https://upload.wikimedia.org/wikipedia/commons/b/be/VeKings.png"
					)
					),
					true
					),
					"info_url"    =>    Tuple(
					Enum<1u8>(
					Enum<13u8>(
					"https://developers.radixdlt.com/ecosystem"
					)
					),
					true
					),
					"name"    =>    Tuple(
					Enum<1u8>(
					Enum<0u8>(
					"SandboxNFT"
					)
					),
					true
					),
					"tags"    =>    Tuple(
					Enum<1u8>(
					Enum<128u8>(
					Array<String>(
					"collection",
					"sandbox",
					"example-tag"
					)
					)
					),
					true
					)
					),
					Map<String,    Enum>()
					)
					Enum<0u8>();
		"""
	}

	static func createNonFungibleTokensRawManifest(account: AccountAddress, nrOfTokens: Int = 1) -> String {
		let instructions = if nrOfTokens == 1 {
			createMultipleIdsNonFungibleResourceRawInstruction
		} else {
			Array(repeating: createSmallNonFungbileResourceRawInstruction, count: nrOfTokens).joined(separator: "\n")
		}

		return """
		\(instructions)
		CALL_METHOD
		Address("\(account.address)")
		"try_deposit_batch_or_abort"
		Expression("ENTIRE_WORKTOP")
		Enum<0u8>();
		"""
	}
}
