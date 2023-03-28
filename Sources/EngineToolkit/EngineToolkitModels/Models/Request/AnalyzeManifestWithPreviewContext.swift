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
public struct AnalyzeManifestWithPreviewContextResponse: Sendable, Codable, Equatable {
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
public struct EncounteredAddresses: Sendable, Codable, Equatable {
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
public struct EncounteredComponents: Sendable, Codable, Equatable {
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
public struct AccountWithdraw: Sendable, Codable, Equatable {
	public let componentAddress: ComponentAddress
	public let resourceSpecifier: ResourceSpecifier

	enum CodingKeys: String, CodingKey {
		case componentAddress = "component_address"
		case resourceSpecifier = "resource_specifier"
	}
}

// MARK: - AccountDeposit
public enum AccountDeposit: Sendable, Codable, Equatable {
	case exact(
		componentAddress: ComponentAddress,
		resourceSpecifier: ResourceSpecifier
	)
	case estimate(
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
public enum ResourceSpecifier: Sendable, Codable, Equatable {
	case amount(ResourceAddress, Decimal_)
	case ids(ResourceAddress, Set<NonFungibleLocalIdInternal>)

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
		case amount = "Amount"
		case ids = "Ids"
	}

	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)

		switch self {
		case let .amount(resourceAddress, amount):
			try container.encode(Kind.amount, forKey: .type)
			try container.encode(resourceAddress, forKey: .resourceAddress)
			try container.encode(amount.value, forKey: .amount)
		case let .ids(resourceAddress, ids):
			try container.encode(Kind.ids, forKey: .type)
			try container.encode(resourceAddress, forKey: .resourceAddress)
			try container.encode(ids, forKey: .ids)
		}
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind = try container.decode(Kind.self, forKey: .type)
		switch kind {
		case .amount:
			self = try .amount(
				container.decode(ResourceAddress.self, forKey: .resourceAddress),
				Decimal_(value: container.decode(String.self, forKey: .amount))
			)
		case .ids:
			self = try .ids(
				container.decode(ResourceAddress.self, forKey: .resourceAddress),
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

	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)

		switch self {
		case let .exact(componentAddress, resourceSpecifier):
			try container.encode(Kind.exact, forKey: .type)
			try container.encode(componentAddress, forKey: .componentAddress)
			try container.encode(resourceSpecifier, forKey: .resourceSpecifier)
		case let .estimate(index, componentAddress, resourceSpecifier):
			try container.encode(Kind.estimate, forKey: .type)
			try container.encode(String(index), forKey: .index)
			try container.encode(componentAddress, forKey: .componentAddress)
			try container.encode(resourceSpecifier, forKey: .resourceSpecifier)
		}
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind = try container.decode(Kind.self, forKey: .type)
		switch kind {
		case .exact:
			self = try .exact(
				componentAddress: container.decode(ComponentAddress.self, forKey: .componentAddress),
				resourceSpecifier: container.decode(ResourceSpecifier.self, forKey: .resourceSpecifier)
			)
		case .estimate:
			self = try .estimate(
				index: decodeAndConvertToNumericType(container: container, key: .index),
				componentAddress: container.decode(ComponentAddress.self, forKey: .componentAddress),
				resourceSpecifier: container.decode(ResourceSpecifier.self, forKey: .resourceSpecifier)
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
