import ComposableArchitecture
import FeaturePrelude

// MARK: - TransactionReview
public struct TransactionReview: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var message: String?
		public var presenting: IdentifiedArrayOf<Dapp>?
		public var withdrawing: IdentifiedArrayOf<TransactionReviewAccount.State>?
		public var usedDapps: TransactionReviewDappsUsed.State
		public var depositing: IdentifiedArrayOf<TransactionReviewAccount.State>?
		public var networkFee: BigDecimal
		public var isNetworkCongested: Bool

		public struct Dapp: Sendable, Identifiable, Hashable {
			public let id: AccountAddress.ID
			public let name: String
			public let thumbnail: URL?

			public init(id: AccountAddress.ID, name: String, thumbnail: URL?) {
				self.id = id
				self.name = name
				self.thumbnail = thumbnail
			}
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case customizeNetworkFeeTapped
		case customizeGuaranteesTapped
	}

	public enum ChildAction: Sendable, Equatable {
		case account(id: AccountAddress.ID, action: TransactionReviewAccount.Action)
		case dapp(TransactionReviewDappsUsed.Action)
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .none
		case .customizeNetworkFeeTapped:
			return .none
		case .customizeGuaranteesTapped:
			return .none
		}
	}
}

extension TransactionReview.State {
	public static let mock0 = Self(message: "Royalties claim",
	                               presenting: [.mock1, .mock0],
	                               withdrawing: [.mockWithdraw0],
	                               usedDapps: .init(isExpanded: false, dapps: []),
	                               depositing: [.mockDeposit1],
	                               networkFee: 0.1,
	                               isNetworkCongested: false)

	public static let mock1 = Self(message: "Royalties claim",
	                               withdrawing: [.mockWithdraw0, .mockWithdraw1],
	                               usedDapps: .init(isExpanded: true, dapps: [.mock3, .mock2]),
	                               depositing: [.mockDeposit2],
	                               networkFee: 0.2,
	                               isNetworkCongested: false)
}

extension TransactionReview.State.Dapp {
	public static let mock0 = Self(id: .deadbeef32Bytes, name: "Collabofi User Badge", thumbnail: nil)
	public static let mock1 = Self(id: .deadbeef64Bytes, name: "Oh Babylon Founder NFT", thumbnail: nil)
	public static let mock2 = Self(id: "lkjl", name: "Megaswap", thumbnail: nil)
	public static let mock3 = Self(id: "lkhgh", name: "Superswap", thumbnail: nil)
}

extension TransactionReviewAccount.State {
	public static let mockWithdraw0 = Self(account: .mockUser0, details: [.mock0, .mock1])

	public static let mockWithdraw1 = Self(account: .mockUser1, details: [.mock1, .mock3, .mock4])

	public static let mockWithdraw2 = Self(account: .mockUser0, details: [.mock1, .mock3])

	public static let mockDeposit1 = Self(account: .mockExternal0, details: [.mock1, .mock3, .mock4])

	public static let mockDeposit2 = Self(account: .mockExternal1, details: [.mock1, .mock3])
}

extension TransactionReviewAccount.State.Account {
	public static let mockUser0 = user(.init(address: .mock0,
	                                         label: "My Main Account",
	                                         appearanceID: ._1))

	public static let mockUser1 = user(.init(address: .mock1,
	                                         label: "My Savings Account",
	                                         appearanceID: ._2))

	public static let mockExternal0 = external(.mock2, approved: true)
	public static let mockExternal1 = external(.mock2, approved: false)
}

extension AccountAddress {
	public static let mock0 = try! Self(address: "account_tdx_b_k591p8y440g69dlqnuzghu84e84ak088fah9u6ay440g6pzq8y4")
	public static let mock1 = try! Self(address: "account_tdx_b_e84ak088fah9u6ad6j9dlqnuz84e84ak088fau6ad6j9dlqnuzk")
	public static let mock2 = try! Self(address: "account_tdx_b_1pzq8y440g6nc4vuz0ghu84e84ak088fah9u6ad6j9dlqnuzk59")
}

extension TransactionReviewAccount.State.Details {
	public static let mock0 = Self(metadata: .init(name: "TSLA", thumbnail: .placeholder),
	                               transferred: .token(1.0396, guaranteed: 1.0188, dollars: 301.91))

	public static let mock1 = Self(metadata: .init(name: "XRD", thumbnail: .placeholder),
	                               transferred: .token(500, guaranteed: nil, dollars: 301.91))

	public static let mock2 = Self(metadata: .init(name: "PXL", thumbnail: .placeholder),
	                               transferred: .token(5.123, guaranteed: 5.10, dollars: nil))

	public static let mock3 = Self(metadata: .init(name: "PXL", thumbnail: .placeholder),
	                               transferred: .token(5.123, guaranteed: nil, dollars: nil))

	public static let mock4 = Self(metadata: .init(name: "Block 14F5", thumbnail: .placeholder),
	                               transferred: .nft)
}

public func decodeActions() {
	guard let data = fullResponse.data(using: .utf8) else {
		print("decodeActions failed data")
		return
	}

	print("Data: \(String(data: data, encoding: .utf8))")

	let decoder = JSONDecoder()

	guard let action = try? decoder.decode(TransactionPreviewResponse.self, from: data) else {
		print("decodeActions failed decoder")
		return
	}

	print("decodeActions success")
	print(action)
}

// MARK: - TransactionPreviewResponse
public struct TransactionPreviewResponse: Codable, Sendable, Hashable {
	public let addressesEncountered: Addresses
	public let proofs: [Proof]
	public let accountActions: Actions

	public enum CodingKeys: String, CodingKey {
		case addressesEncountered = "addresses_encountered"
		case proofs
		case accountActions = "account_actions"
	}

	public struct Addresses: Codable, Sendable, Hashable {
		public let packageAddresses: [PackageAddress]
		public let componentAddresses: [ComponentAddress]
		public let resourceAddresses: [ResourceAddress]

		public enum CodingKeys: String, CodingKey {
			case packageAddresses = "package_addresses"
			case componentAddresses = "component_addresses"
			case resourceAddresses = "resource_addresses"
		}
	}

	public struct Proof: Codable, Sendable, Hashable {
		public let origin: ComponentAddress
		public let resourceAddress: ResourceAddress
		public let quantity: TransactionQuantity

		public enum CodingKeys: String, CodingKey {
			case origin
			case resourceAddress = "resource_address"
			case quantity
		}
	}

	public struct Actions: Codable, Sendable, Hashable {
		public let withdraws: [AccountAction]
		public let deposits: [AccountAction]
	}
}

// MARK: - TransactionQuantity
public struct TransactionQuantity: Codable, Sendable, Hashable {
	public let type: QuantityType
	public let amount: BigDecimal

	public enum QuantityType: String, Codable, Sendable, Hashable {
		case amount = "Amount"
	}
}

// MARK: - AccountAction
public struct AccountAction: Codable, Sendable, Hashable {
	public let componentAddress: ComponentAddress

	public let resourceAddress: ResourceAddress

	public let amount: BigDecimal

	public enum CodingKeys: String, CodingKey {
		case componentAddress = "component_address"
		case resourceAddress = "resource_address"
		case amount
	}
}

extension Collection<AccountAction> {
	public var groupedByAccount: [ComponentAddress: [AccountAction]] {
		.init(grouping: self, by: \.componentAddress)
	}
}

// MARK: - TransactionAmount
@propertyWrapper
struct TransactionAmount: Sendable, Hashable {
	let wrappedValue: BigDecimal
}

// MARK: Codable
extension TransactionAmount: Codable {
	init(from decoder: Decoder) throws {
		var container = try decoder.singleValueContainer()
		let string = try container.decode(String.self)
		self.wrappedValue = try BigDecimal(fromString: string)
	}

	func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(self.wrappedValue)
	}
}

private let actionsResponse =
	"""
	{
		"withdraws": [
		  {
			"component_address": {
			  "type": "ComponentAddress",
			  "address": "account_tdx_b_1pp3eaya2hehlxqgmva6vutzec68cv7vuaye5rl9nqunsutnvhm"
			},
			"resource_address": {
			  "type": "ResourceAddress",
			  "address": "resource_tdx_b_1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq8z96qp"
			},
			"amount": "100"
		  }
		],
		"deposits": [
		  {
			"component_address": {
			  "type": "ComponentAddress",
			  "address": "account_tdx_b_1pp3eaya2hehlxqgmva6vutzec68cv7vuaye5rl9nqunsutnvhm"
			},
			"resource_address": {
			  "type": "ResourceAddress",
			  "address": "resource_tdx_b_1qre9sv98scqut4k9g3j6kxuvscczv0lzumefwgwhuf6qdu4c3r"
			},
			"amount": "0.760757908055004258"
		  }
		]
	  }
	"""

private let fullResponse =
	"""
	{
	  "addresses_encountered": {
		"package_addresses": [],
		"component_addresses": [
		  {
			"type": "ComponentAddress",
			"address": "component_tdx_b_1qt7c7ws0a4f3wd3mwtcj4acvn87w4as9zyvkx3wwq8lskwe5zm"
		  },
		  {
			"type": "ComponentAddress",
			"address": "account_tdx_b_1pp3eaya2hehlxqgmva6vutzec68cv7vuaye5rl9nqunsutnvhm"
		  }
		],
		"resource_addresses": [
		  {
			"type": "ResourceAddress",
			"address": "resource_tdx_b_1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq8z96qp"
		  },
		  {
			"type": "ResourceAddress",
			"address": "resource_tdx_b_1qre9sv98scqut4k9g3j6kxuvscczv0lzumefwgwhuf6qdu4c3r"
		  }
		]
	  },
	  "proofs": [
		{
		  "origin": {
			"type": "ComponentAddress",
			"address": "account_tdx_b_1pp3eaya2hehlxqgmva6vutzec68cv7vuaye5rl9nqunsutnvhm"
		  },
		  "resource_address": {
			"type": "ResourceAddress",
			"address": "resource_tdx_b_1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq8z96qp"
		  },
		  "quantity": {
			"type": "Amount",
			"amount": "250"
		  }
		}
	  ],
	  "account_actions": {
		"withdraws": [
		  {
			"component_address": {
			  "type": "ComponentAddress",
			  "address": "account_tdx_b_1pp3eaya2hehlxqgmva6vutzec68cv7vuaye5rl9nqunsutnvhm"
			},
			"resource_address": {
			  "type": "ResourceAddress",
			  "address": "resource_tdx_b_1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq8z96qp"
			},
			"amount": "100"
		  }
		],
		"deposits": [
		  {
			"component_address": {
			  "type": "ComponentAddress",
			  "address": "account_tdx_b_1pp3eaya2hehlxqgmva6vutzec68cv7vuaye5rl9nqunsutnvhm"
			},
			"resource_address": {
			  "type": "ResourceAddress",
			  "address": "resource_tdx_b_1qre9sv98scqut4k9g3j6kxuvscczv0lzumefwgwhuf6qdu4c3r"
			},
			"amount": "0.760757908055004258"
		  }
		]
	  }
	}
	"""

// MARK: - AddressType
public protocol AddressType {
	static var kind: ValueKind { get }
	static func embed(address: NewAddress<Self>) -> Value_
}

// MARK: - ResourceAddressType
public enum ResourceAddressType: AddressType {
	public static let kind: ValueKind = .resourceAddress

	public static func embed(address: NewAddress<Self>) -> Value_ {
		.resourceAddress(.init(address: address.address))
	}
}

// MARK: - ComponentAddressType
public enum ComponentAddressType: AddressType {
	public static let kind: ValueKind = .componentAddress

	public static func embed(address: NewAddress<Self>) -> Value_ {
		.componentAddress(.init(address: address.address))
	}
}

// MARK: - PackageAddressType
public enum PackageAddressType: AddressType {
	public static let kind: ValueKind = .packageAddress

	public static func embed(address: NewAddress<Self>) -> Value_ {
		.packageAddress(.init(address: address.address))
	}
}

// MARK: - NewAddress
public struct NewAddress<T: AddressType>: Sendable, Codable, Hashable {
	public let address: String

	public init(address: String) {
		// TODO: Perform some simple Bech32m validation.
		self.address = address
	}
}

// MARK: ValueProtocol
extension NewAddress: ValueProtocol {
	public static var kind: ValueKind { T.kind }

	public func embedValue() -> Value_ {
		T.embed(address: self)
	}
}

// MARK: - AnyAddress
public struct AnyAddress: Sendable, Codable, Hashable {
	public let address: String
	public let kind: ValueKind

	init<T: AddressType>(_ address: NewAddress<T>) {
		self.address = address.address
		self.kind = T.kind
	}

	public var resourceAddress: NewAddress<ResourceAddressType>? {
		guard kind == .resourceAddress else { return nil }
		return .init(address: address)
	}

	public var componentAddress: NewAddress<ComponentAddressType>? {
		guard kind == .componentAddress else { return nil }
		return .init(address: address)
	}

	public var packageAddress: NewAddress<PackageAddressType>? {
		guard kind == .packageAddress else { return nil }
		return .init(address: address)
	}
}

extension NewAddress {
	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case address, type
	}

	// MARK: Codable
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)
		try container.encode(String(address), forKey: .address)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind = try container.decode(ValueKind.self, forKey: .type)

		if kind != Self.kind {
			throw InternalDecodingFailure.valueTypeDiscriminatorMismatch(expectedAnyOf: [Self.kind], butGot: kind)
		}

		// Decoding `address`
		try self.init(address: container.decode(String.self, forKey: .address))
	}
}
