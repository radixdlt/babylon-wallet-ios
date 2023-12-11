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
			try accountTryDepositEntireWorktopOrAbort(componentAddress.intoEngine(), nil)
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
				divisibility: 10,
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
			.accountTryDepositEntireWorktopOrAbort(accountAddress: account.intoEngine(), authorizedDepositorBadge: nil)
			.build(networkId: networkID.rawValue)
	}

	public static func manifestForCreateMultipleFungibleTokens(
		account: AccountAddress,
		networkID: NetworkID
	) throws -> TransactionManifest {
		try ManifestBuilder.make {
			for _ in 0 ..< 20 {
				try ManifestBuilder.createFungibleResourceManager(
					.none,
					true,
					10,
					.init(value: "100000"),
					.init(mintRoles: nil, burnRoles: nil, freezeRoles: nil, recallRoles: nil, withdrawRoles: nil, depositRoles: nil),
					.init(
						init: [
							"name": .init(value: .stringValue(value: "MyResource"), lock: false),
							"symbol": .init(value: .stringValue(value: "VIP"), lock: false),
							"description": .init(value: .stringValue(value: "A very innovative and important resource"), lock: false),
							"icon_url": .init(value: .urlValue(value: "https://i.imgur.com/A2itmif.jpeg"), lock: false),
						],
						roles: [:]
					),
					nil
				)
			}
			try accountTryDepositEntireWorktopOrAbort(account.intoEngine(), nil)
		}
		.build(networkId: networkID.rawValue)
	}

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
