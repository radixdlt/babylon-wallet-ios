// MARK: - AnalyzeManifestWithPreviewContextRequest
public struct AnalyzeManifestWithPreviewContextRequest: Codable {
	public let networkId: NetworkID
	public let manifest: TransactionManifest
	public let transactionReceipt: [UInt8]

	enum CodingKeys: String, CodingKey {
		case networkId = "network_id"
		case manifest
		case transactionReceipt = "transaction_receipt"
	}

	public init(
		networkId: NetworkID,
		manifest: TransactionManifest,
		transactionReceipt: [UInt8]
	) {
		self.networkId = networkId
		self.manifest = manifest
		self.transactionReceipt = transactionReceipt
	}
}

// MARK: - AnalyzeManifestWithPreviewContextResponse
public struct AnalyzeManifestWithPreviewContextResponse: Sendable, Decodable, Equatable {
	public let encounteredAddresses: EncounteredAddresses
	public let accountsRequiringAuth: Set<AccountAddress_>
	public let accountProofResources: Set<ResourceAddress>
	public let accountWithdraws: [AccountWithdraw]
	public let accountDeposits: [AccountDeposit]
	public let newlyCreatedEntities: NewlyCreatedEntities?

	enum CodingKeys: String, CodingKey {
		case encounteredAddresses = "encountered_addresses"
		case accountsRequiringAuth = "accounts_requiring_auth"
		case accountProofResources = "account_proof_resources"
		case accountWithdraws = "account_withdraws"
		case accountDeposits = "account_deposits"
		case newlyCreatedEntities = "newly_created"
	}
}

// MARK: - EncounteredAddresses
public struct EncounteredAddresses: Sendable, Decodable, Equatable {
	public let componentAddresses: EncounteredComponents
	public let resourceAddresses: Set<ResourceAddress>
	public let packageAddresses: Set<PackageAddress>

	enum CodingKeys: String, CodingKey {
		case componentAddresses = "component_addresses"
		case resourceAddresses = "resource_addresses"
		case packageAddresses = "package_addresses"
	}
}

// MARK: - EncounteredComponents
public struct EncounteredComponents: Sendable, Decodable, Equatable {
	public let userApplications: Set<ComponentAddress>
	public let accounts: Set<AccountAddress_>
	public let identities: Set<IdentityAddress_>
	public let clocks: Set<ComponentAddress>
	public let epochManagers: Set<ComponentAddress>
	public let validators: Set<ComponentAddress>
	public let accessController: Set<AccessControllerAddress>

	enum CodingKeys: String, CodingKey {
		case userApplications = "user_applications"
		case accounts
		case identities
		case clocks
		case epochManagers = "epoch_managers"
		case validators
		case accessController = "access_controller"
	}
}

// MARK: - AccountWithdraw
public struct AccountWithdraw: Sendable, Decodable, Equatable {
	// Should be AccountAddress?
	public let componentAddress: ComponentAddress
	public let resourceQuantifier: ResourceQuantifier

	enum CodingKeys: String, CodingKey {
		case componentAddress = "component_address"
		case resourceQuantifier = "resource_quantifier"
	}
}

// MARK: - AccountDeposit
public enum AccountDeposit: Sendable, Decodable, Equatable {
	case exact(
		componentAddress: ComponentAddress, // Should be AccountAddress?
		resourceQuantifier: ResourceQuantifier
	)
	case estimate(
		index: UInt32,
		componentAddress: ComponentAddress, // Should be AccountAddress?
		resourceQuantifier: ResourceQuantifier
	)

	enum CodingKeys: String, CodingKey {
		case type
		case index = "instruction_index"
		case componentAddress = "component_address"
		case resourceSpecifier = "resource_specifier"
	}
}

// MARK: - NewlyCreatedEntities
public struct NewlyCreatedEntities: Sendable, Decodable, Equatable {
	public let resources: [NewlyCreatedEntity]
}

// MARK: - NewlyCreatedEntity
public struct NewlyCreatedEntity: Sendable, Decodable, Equatable {
	public let metadata: [MetadataKeyValue]
}

// MARK: - MetadataKeyValue
public struct MetadataKeyValue: Sendable, Decodable, Equatable {
	public let key: String
	public let value: MetadataValue
}

// MARK: - MetadataValueType
// TODO: Validate the implementation against RET, this was just quickly implemented
enum MetadataValueType: String, Decodable {
	case bool = "Bool"
	case u8 = "U8"
	case u32 = "U32"
	case u64 = "U64"
	case i32 = "I32"
	case i64 = "I64"
	case string = "String"
	case decimal = "Decimal"
	case address = "Address"
	case nonFungibleLocalId = "NonFungibleLocalId"
	case nonFungibleGlobalId = "NonFungibleGlobalId"
	case publicKey = "PublicKey"
	case instant = "Instant"
	case url = "Url"
}

// MARK: - MetadataValue
public enum MetadataValue: Sendable, Decodable, Equatable {
	case boolean(Bool)

	case i32(Int32)
	case i64(Int64)

	case u8(UInt8)
	case u32(UInt32)
	case u64(UInt64)

	case string(String)

	case decimal(Decimal_)
	case address(Address_)

	case publickKey(PublicKey)

	case nonFungibleLocalId(String)
	case nonFungibleGlobalId(String)
	case instant(String)
	case url(String)

	enum CodingKeys: CodingKey {
		case type, value
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: MetadataValueType = try container.decode(MetadataValueType.self, forKey: .type)

		switch kind {
		case .bool:
			self = try .boolean(container.decode(Bool.self, forKey: .value))

		case .i32:
			self = try .i32(container.decode(Int32.self, forKey: .value))

		case .i64:
			self = try .i64(container.decode(Int64.self, forKey: .value))

		case .u8:
			self = try .u8(container.decode(UInt8.self, forKey: .value))

		case .u32:
			self = try .u32(container.decode(UInt32.self, forKey: .value))

		case .u64:
			self = try .u64(container.decode(UInt64.self, forKey: .value))

		case .string:
			self = try .string(container.decode(String.self, forKey: .value))

		case .decimal:
			self = try .decimal(.init(from: decoder))

		case .address:
			self = try .address(.init(from: decoder))

		case .nonFungibleLocalId:
			self = try .nonFungibleLocalId(container.decode(String.self, forKey: .value))

		case .nonFungibleGlobalId:
			self = try .nonFungibleGlobalId(container.decode(String.self, forKey: .value))

		case .publicKey:
			self = try .publickKey(container.decode(PublicKey.self, forKey: .value))

		case .instant:
			self = try .instant(container.decode(String.self, forKey: .value))

		case .url:
			self = try .instant(container.decode(String.self, forKey: .value))
		}
	}

	public enum PublicKey: Decodable, Equatable, Sendable {
		private enum CodingKeys: String, CodingKey {
			case curve, public_key
		}

		case ecdsaSecp256k1(String)
		case eddsaEd25519(String)

		enum CurveType: String, Decodable {
			case ecdsaSecp256k1 = "EcdsaSecp256k1"
			case eddsaEd25519 = "EddsaEd25519"
		}

		public init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			let curve = try container.decode(CurveType.self, forKey: .curve)
			let publicKey = try container.decode(String.self, forKey: .public_key)

			switch curve {
			case .ecdsaSecp256k1:
				self = .ecdsaSecp256k1(publicKey)
			case .eddsaEd25519:
				self = .eddsaEd25519(publicKey)
			}
		}
	}
}

// MARK: - ResourceQuantifier
// TODO: Validate the new format against RET, this was just quickly implemented
public enum ResourceQuantifier: Sendable, Decodable, Equatable {
	case amount(Resource, Decimal_)
	case ids(Resource, Set<NonFungibleLocalIdInternal>)

	enum CodingKeys: String, CodingKey {
		case type
		case amount
		case ids
		case resourceAddress = "resource_address"
	}

	public enum Resource: Decodable, Equatable, Sendable {
		enum CodingKeys: CodingKey {
			case type, address, index
		}

		enum ResourceType: String, Decodable {
			case existing = "Existing"
			case newlyCreated = "NewlyCreated"
		}

		case existing(ResourceAddress)
		case newlyCreated(index: String)

		public init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			let type = try container.decode(ResourceType.self, forKey: .type)

			switch type {
			case .existing:
				self = try .existing(container.decode(ResourceAddress.self, forKey: .address))
			case .newlyCreated:
				self = try .newlyCreated(index: container.decode(String.self, forKey: .type))
			}
		}
	}
}

// MARK: Codable stuff

public extension ResourceQuantifier {
	internal enum Kind: String, Codable {
		case amount = "Amount"
		case ids = "Ids"
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind = try container.decode(Kind.self, forKey: .type)
		switch kind {
		case .amount:
			self = try .amount(
				container.decode(Resource.self, forKey: .resourceAddress),
				Decimal_(value: container.decode(String.self, forKey: .amount))
			)
		case .ids:
			self = try .ids(
				container.decode(Resource.self, forKey: .resourceAddress),
				container.decode(Set<NonFungibleLocalIdInternal>.self, forKey: .ids)
			)
		}
	}
}

public extension AccountDeposit {
	internal enum Kind: String, Codable {
		case exact = "Exact"
		case estimate = "Estimate"
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind = try container.decode(Kind.self, forKey: .type)
		switch kind {
		case .exact:
			self = try .exact(
				componentAddress: container.decode(ComponentAddress.self, forKey: .componentAddress),
				resourceQuantifier: container.decode(ResourceQuantifier.self, forKey: .resourceSpecifier)
			)
		case .estimate:
			self = try .estimate(
				index: decodeAndConvertToNumericType(container: container, key: .index),
				componentAddress: container.decode(ComponentAddress.self, forKey: .componentAddress),
				resourceQuantifier: container.decode(ResourceQuantifier.self, forKey: .resourceSpecifier)
			)
		}
	}
}

public extension AnalyzeManifestWithPreviewContextRequest {
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(manifest, forKey: .manifest)
		try container.encode(String(networkId), forKey: .networkId)
		try container.encode(transactionReceipt.hex(), forKey: .transactionReceipt)
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		try self.init(
			networkId: NetworkID(decodeAndConvertToNumericType(container: container, key: .networkId)),
			manifest: container.decode(TransactionManifest.self, forKey: .manifest),
			transactionReceipt: [UInt8](hex: container.decode(String.self, forKey: .transactionReceipt))
		)
	}
}
