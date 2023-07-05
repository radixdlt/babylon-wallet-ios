import CasePaths
import Foundation

// MARK: - AnalyzeTransactionExecutionRequest
public struct AnalyzeTransactionExecutionRequest: Encodable {
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

// MARK: - AnalyzeTransactionExecutionResponse
public struct AnalyzeTransactionExecutionResponse: Sendable, Decodable, Hashable {
	public let encounteredAddresses: EncounteredAddresses
	public let accountsRequiringAuth: Set<ComponentAddress>
	public let accountProofResources: Set<ResourceAddress>
	public let accountWithdraws: [AccountWithdraw]
	public let accountDeposits: [AccountDeposit]
	public let newlyCreated: NewlyCreated?

	enum CodingKeys: String, CodingKey {
		case encounteredAddresses = "encountered_addresses"
		case accountsRequiringAuth = "accounts_requiring_auth"
		case accountProofResources = "account_proof_resources"
		case accountWithdraws = "account_withdraws"
		case accountDeposits = "account_deposits"
		case newlyCreated = "newly_created"
	}
}

// MARK: - EncounteredAddresses
public struct EncounteredAddresses: Sendable, Decodable, Hashable {
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
public struct EncounteredComponents: Sendable, Decodable, Hashable {
	public let accessController: Set<AccessControllerAddress>
	public let accounts: Set<AccountAddress>
	public let consensusManagers: Set<ConsensusManagerAddress>
	public let identities: Set<IdentityAddress>
	public let userApplications: Set<ComponentAddress>
	public let validators: Set<ValidatorAddress>

	enum CodingKeys: String, CodingKey {
		case accessController = "access_controller"
		case accounts
		case consensusManagers = "consensus_managers"
		case identities
		case userApplications = "user_applications"
		case validators
	}
}

// MARK: - AccountWithdraw
public struct AccountWithdraw: Sendable, Decodable, Hashable {
	public let componentAddress: ComponentAddress
	public let resourceQuantifier: ResourceQuantifier

	enum CodingKeys: String, CodingKey {
		case componentAddress = "component_address"
		case resourceQuantifier = "resource_quantifier"
	}
}

// MARK: - AccountDeposit
public enum AccountDeposit: Sendable, Decodable, Hashable {
	case guaranteed(
		componentAddress: ComponentAddress,
		resourceQuantifier: ResourceQuantifier
	)
	case predicted(
		index: UInt32,
		componentAddress: ComponentAddress,
		resourceQuantifier: ResourceQuantifier
	)

	enum CodingKeys: String, CodingKey {
		case type
		case index = "instruction_index"
		case componentAddress = "component_address"
		case resourceQuantifier = "resource_quantifier"
	}
}

// MARK: - NewlyCreated
public struct NewlyCreated: Sendable, Decodable, Hashable {
	public var resources: [NewlyCreatedResource]
}

// MARK: - NewlyCreatedResource
public struct NewlyCreatedResource: Sendable, Decodable, Hashable {
	public struct MetadataKeyValue: Sendable, Decodable, Hashable {
		public let key: String
		public let value: MetadataValue
	}

	public var metadata: [MetadataKeyValue]

	public var name: String? {
		metadata["name"]?.string
	}

	public var description: String? {
		metadata["description"]?.string
	}

	public var symbol: String? {
		metadata["symbol"]?.string
	}

	public var iconURL: URL? {
		metadata["icon_url"]?.string.flatMap(URL.init)
	}
}

extension [NewlyCreatedResource.MetadataKeyValue] {
	public subscript(_ key: String) -> MetadataValue? {
		first { $0.key == key }?.value
	}
}

// MARK: - ResourceQuantifier
public enum ResourceQuantifier: Sendable, Decodable, Hashable {
	case amount(ResourceManagerSpecifier, Decimal_)
	case ids(ResourceManagerSpecifier, Set<NonFungibleLocalId>)

	enum CodingKeys: String, CodingKey {
		case type
		case amount
		case ids
		case resourceAddress = "resource_address"
	}
}

// MARK: - ResourceManagerSpecifier
public enum ResourceManagerSpecifier: Sendable, Decodable, Hashable {
	case existing(ResourceAddress)
	case newlyCreated(index: Int)

	public var existing: ResourceAddress? {
		guard case let .existing(resourceAddress) = self else {
			return nil
		}
		return resourceAddress
	}

	enum CodingKeys: String, CodingKey {
		case type
		case address
		case index
	}

	internal enum Kind: String, Codable {
		case existing = "Existing"
		case newlyCreated = "NewlyCreated"
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind = try container.decode(Kind.self, forKey: .type)

		switch kind {
		case .existing:
			self = try .existing(container.decode(ResourceAddress.self, forKey: .address))
		case .newlyCreated:
			self = try .newlyCreated(index: decodeAndConvertToNumericType(container: container, key: .index))
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
				container.decode(ResourceManagerSpecifier.self, forKey: .resourceAddress),
				Decimal_(value: container.decode(String.self, forKey: .amount))
			)
		case .ids:
			self = try .ids(
				container.decode(ResourceManagerSpecifier.self, forKey: .resourceAddress),
				container.decode(Set<NonFungibleLocalId>.self, forKey: .ids)
			)
		}
	}
}

public extension AccountDeposit {
	internal enum Kind: String, Codable {
		case guaranteed = "Guaranteed"
		case predicted = "Predicted"
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind = try container.decode(Kind.self, forKey: .type)
		switch kind {
		case .guaranteed:
			self = try .guaranteed(
				componentAddress: container.decode(ComponentAddress.self, forKey: .componentAddress),
				resourceQuantifier: container.decode(ResourceQuantifier.self, forKey: .resourceQuantifier)
			)
		case .predicted:
			self = try .predicted(
				index: decodeAndConvertToNumericType(container: container, key: .index),
				componentAddress: container.decode(ComponentAddress.self, forKey: .componentAddress),
				resourceQuantifier: container.decode(ResourceQuantifier.self, forKey: .resourceQuantifier)
			)
		}
	}
}

public extension AnalyzeTransactionExecutionRequest {
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(manifest, forKey: .manifest)
		try container.encode(String(networkId), forKey: .networkId)
		try container.encode(transactionReceipt.hex(), forKey: .transactionReceipt)
	}
}
