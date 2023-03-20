import ComposableArchitecture
import FeaturePrelude

// MARK: - TransactionReview
public struct TransactionReview: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var message: String?

		public var withdrawing: IdentifiedArrayOf<TransactionReviewAccount.State>?
		public var dAppsUsed: TransactionReviewDappsUsed.State?
		public var depositing: IdentifiedArrayOf<TransactionReviewAccount.State>?

		public var presenting: IdentifiedArrayOf<Dapp>?

		public var networkFee: TransactionReviewNetworkFee.State

		public struct Dapp: Sendable, Identifiable, Hashable {
			public let id: AccountAddress.ID
			public let thumbnail: URL?
			public let name: String
			public let description: String?

			public init(id: AccountAddress.ID, thumbnail: URL?, name: String, description: String?) {
				self.id = id
				self.thumbnail = thumbnail
				self.name = name
				self.description = description
			}
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case closeTapped
		case showRawTransactionTapped

		case customizeGuaranteesTapped
		case approveTapped
	}

	public enum ChildAction: Sendable, Equatable {
		case account(id: AccountAddress.ID, action: TransactionReviewAccount.Action)
		case dAppsUsed(TransactionReviewDappsUsed.Action)
		case networkFee(TransactionReviewNetworkFee.Action)
	}

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.networkFee, action: /Action.child .. ChildAction.networkFee) {
			TransactionReviewNetworkFee()
		}
		Reduce(core)
			.ifLet(\.dAppsUsed, action: /Action.child .. ChildAction.dAppsUsed) {
				TransactionReviewDappsUsed()
			}
//			.ifLet(\.depositing, action: /Action.child .. ChildAction.depositing) {
//
//			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .none
		case .closeTapped:
			return .none
		case .showRawTransactionTapped:
			return .none

		case .customizeGuaranteesTapped:
			return .none

		case .approveTapped:
			return .none
		}
	}
}

extension TransactionReview.State {
	public static let mock0 = Self(message: "Royalties claim",
	                               withdrawing: [.mockWithdraw0],
	                               dAppsUsed: .init(isExpanded: false, dApps: []),
	                               depositing: [.mockDeposit1],
	                               presenting: [.mock1, .mock0],
	                               networkFee: .init(fee: 0.1, isCongested: false))

	public static let mock1 = Self(message: "Royalties claim",
	                               withdrawing: [.mockWithdraw0, .mockWithdraw1],
	                               dAppsUsed: .init(isExpanded: true, dApps: [.mock3, .mock2, .mock1]),
	                               depositing: [.mockDeposit2],
	                               networkFee: .init(fee: 0.2, isCongested: true))
}

extension TransactionReview.State.Dapp {
	public static let mock0 = Self(id: .deadbeef32Bytes, thumbnail: nil, name: "Collabofi User Badge", description: nil)
	public static let mock1 = Self(id: .deadbeef64Bytes, thumbnail: nil, name: "Oh Babylon Founder NFT", description: "Investor 2 lines")
	public static let mock2 = Self(id: "lkjl", thumbnail: nil, name: "Megaswap", description: nil)
	public static let mock3 = Self(id: "lkhgh", thumbnail: nil, name: "Superswap", description: nil)
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

extension URL {
	static let mock = URL(string: "test")!
}

extension TransactionReviewAccount.State.Details {
	public static let mock0 = Self(metadata: .init(name: "TSLA", thumbnail: .mock),
	                               transferred: .token(1.0396, guaranteed: 1.0188, dollars: 301.91))

	public static let mock1 = Self(metadata: .init(name: "XRD", thumbnail: .mock),
	                               transferred: .token(500, guaranteed: nil, dollars: 301.91))

	public static let mock2 = Self(metadata: .init(name: "PXL", thumbnail: .mock),
	                               transferred: .token(5.123, guaranteed: 5.10, dollars: nil))

	public static let mock3 = Self(metadata: .init(name: "PXL", thumbnail: .mock),
	                               transferred: .token(5.123, guaranteed: nil, dollars: nil))

	public static let mock4 = Self(metadata: .init(name: "Block 14F5", thumbnail: .mock),
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
		let container = try decoder.singleValueContainer()
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
