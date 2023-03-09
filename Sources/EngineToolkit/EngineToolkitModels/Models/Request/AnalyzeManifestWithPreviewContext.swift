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
public struct AnalyzeManifestWithPreviewContextResponse: Codable {
	public let encounteredAddresses: EncounteredAddresses
	public let accountsRequiringAuth: Set<ComponentAddress>
	public let accountProofResources: Set<ResourceAddress>
	public let accountWithdraws: [AccountWithdraw]
	public let accountDeposits: [AccountDeposit]

	enum CodingKeys: String, CodingKey {
		case encounteredAddresses = "encountered_addresses"
		case accountsRequiringAuth = "accounts_requiring_auth"
		case accountProofResources = "account_proof_resources"
		case accountWithdraws = "account_withdraws"
		case accountDeposits = "account_deposits"
	}
}

// MARK: - EncounteredAddresses
public struct EncounteredAddresses: Codable {
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
public struct EncounteredComponents: Codable {
	public let userApplications: Set<ComponentAddress>
	public let accounts: Set<ComponentAddress>
	public let identities: Set<ComponentAddress>
	public let clocks: Set<ComponentAddress>
	public let epochManagers: Set<ComponentAddress>
	public let validators: Set<ComponentAddress>
	public let accessController: Set<ComponentAddress>

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
public struct AccountWithdraw: Codable {
	public let componentAddress: ComponentAddress
	public let resourceSpecifier: ResourceSpecifier

	enum CodingKeys: String, CodingKey {
		case componentAddress = "component_address"
		case resourceSpecifier = "resource_specifier"
	}
}

// MARK: - AccountDeposit
public enum AccountDeposit: Codable {
	case Exact(
		componentAddress: ComponentAddress,
		resourceSpecifier: ResourceSpecifier
	)
	case Estimate(
		index: UInt32,
		componentAddress: ComponentAddress,
		resourceSpecifier: ResourceSpecifier
	)

	enum CodingKeys: String, CodingKey {
		case type
		case index = "instruction_index"
		case componentAddress = "component_address"
		case resourceSpecifier = "resource_specifier"
	}
}

// MARK: - ResourceSpecifier
public enum ResourceSpecifier: Codable {
	case Amount(ResourceAddress, Decimal_)
	case Ids(ResourceAddress, Set<NonFungibleLocalId>)

	enum CodingKeys: String, CodingKey {
		case type
		case amount
		case ids
		case resourceAddress = "resource_address"
	}
}

// MARK: Codable stuff

public extension ResourceSpecifier {
	internal enum Kind: String, Codable {
		case Amount
		case Ids
	}

	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)

		switch self {
		case let .Amount(resourceAddress, amount):
			try container.encode("Amount", forKey: .type)
			try container.encode(resourceAddress, forKey: .resourceAddress)
			try container.encode(amount.value, forKey: .amount)
		case let .Ids(resourceAddress, ids):
			try container.encode("Ids", forKey: .type)
			try container.encode(resourceAddress, forKey: .resourceAddress)
			try container.encode(ids, forKey: .ids)
		}
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind = try container.decode(Kind.self, forKey: .type)
		switch kind {
		case .Amount:
			self = Self.Amount(
				try container.decode(ResourceAddress.self, forKey: .resourceAddress),
				try Decimal_(value: container.decode(String.self, forKey: .amount))
			)
		case .Ids:
			self = Self.Ids(
				try container.decode(ResourceAddress.self, forKey: .resourceAddress),
				try container.decode(Set<NonFungibleLocalId>.self, forKey: .ids)
			)
		}
	}
}

public extension AccountDeposit {
	internal enum Kind: String, Codable {
		case Exact
		case Estimate
	}

	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)

		switch self {
		case let .Exact(componentAddress, resourceSpecifier):
			try container.encode(Kind.Exact, forKey: .type)
			try container.encode(componentAddress, forKey: .componentAddress)
			try container.encode(resourceSpecifier, forKey: .resourceSpecifier)
		case let .Estimate(index, componentAddress, resourceSpecifier):
			try container.encode(Kind.Estimate, forKey: .type)
			try container.encode(String(index), forKey: .index)
			try container.encode(componentAddress, forKey: .componentAddress)
			try container.encode(resourceSpecifier, forKey: .resourceSpecifier)
		}
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind = try container.decode(Kind.self, forKey: .type)
		switch kind {
		case .Exact:
			self = Self.Exact(
				componentAddress: try container.decode(ComponentAddress.self, forKey: .componentAddress),
				resourceSpecifier: try container.decode(ResourceSpecifier.self, forKey: .resourceSpecifier)
			)
		case .Estimate:
			self = Self.Estimate(
				index: try decodeAndConvertToNumericType(container: container, key: .index),
				componentAddress: try container.decode(ComponentAddress.self, forKey: .componentAddress),
				resourceSpecifier: try container.decode(ResourceSpecifier.self, forKey: .resourceSpecifier)
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
		self.init(
			networkId: try NetworkID(decodeAndConvertToNumericType(container: container, key: .networkId)),
			manifest: try container.decode(TransactionManifest.self, forKey: .manifest),
			transactionReceipt: try [UInt8](hex: container.decode(String.self, forKey: .transactionReceipt))
		)
	}
}
