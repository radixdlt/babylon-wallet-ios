import ComposableArchitecture
import FeaturePrelude

// MARK: - TransactionReview
public struct TransactionReview: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var message: String?

		public var withdrawing: TransactionReviewAccounts.State?
		public var dAppsUsed: TransactionReviewDappsUsed.State?
		public var depositing: TransactionReviewAccounts.State

		public var presenting: TransactionReviewPresenting.State?

		public var networkFee: TransactionReviewNetworkFee.State

		@PresentationState
		public var customizeGuarantees: TransactionReviewGuarantees.State? = nil
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case closeTapped
		case showRawTransactionTapped

		case approveTapped
	}

	public enum ChildAction: Sendable, Equatable {
		case withdrawing(TransactionReviewAccounts.Action)
		case depositing(TransactionReviewAccounts.Action)
		case dAppsUsed(TransactionReviewDappsUsed.Action)
		case presenting(TransactionReviewPresenting.Action)
		case networkFee(TransactionReviewNetworkFee.Action)

		case customizeGuarantees(PresentationAction<TransactionReviewGuarantees.Action>)
	}

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.networkFee, action: /Action.child .. ChildAction.networkFee) {
			TransactionReviewNetworkFee()
		}
		Scope(state: \.depositing, action: /Action.child .. ChildAction.depositing) {
			TransactionReviewAccounts()
		}
		Reduce(core)
			.ifLet(\.dAppsUsed, action: /Action.child .. ChildAction.dAppsUsed) {
				TransactionReviewDappsUsed()
			}
			.ifLet(\.withdrawing, action: /Action.child .. ChildAction.withdrawing) {
				TransactionReviewAccounts()
			}
			.ifLet(\.$customizeGuarantees, action: /Action.child .. ChildAction.customizeGuarantees) {
				TransactionReviewGuarantees()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .none
		case .closeTapped:
			return .none
		case .showRawTransactionTapped:
			return .none

		case .approveTapped:
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .withdrawing:
			return .none

		case .depositing(.delegate(.showCustomizeGuarantees)):
			var accounts = state.depositing.accounts
			for account in accounts {
				let fungibleTransfers = account.transfers.filter { $0.metadata.type == .fungible }
				accounts[id: account.id] = .init(account: account.account, transfers: fungibleTransfers)
			}
			state.customizeGuarantees = .init(transferAccounts: accounts)
			return .none

		case .depositing:
			return .none
		case .dAppsUsed:
			return .none
		case .presenting:
			return .none
		case .networkFee:
			return .none
//		case .customizeGuarantees(.presented(.delegate(.dismiss))):
//
//			return .none

		case .customizeGuarantees(.presented(.delegate(.dismiss))):
			state.customizeGuarantees = nil
			return .none
		case .customizeGuarantees:
			return .none
		}
	}
}

// MARK: Useful types

extension TransactionReview {
	public struct Dapp: Sendable, Identifiable, Hashable {
		public let id: AccountAddress.ID
		public let metadata: Metadata?

		init(id: AccountAddress.ID, metadata: Metadata?) {
			self.id = id
			self.metadata = metadata
		}

		public struct Metadata: Sendable, Hashable {
			public let name: String
			public let thumbnail: URL?
			public let description: String?

			public init(name: String, thumbnail: URL?, description: String?) {
				self.name = name
				self.thumbnail = thumbnail
				self.description = description
			}
		}
	}

	public enum ResourceType: Sendable, Hashable {
		case fungible
		case nonFungible
	}

	public enum Account: Sendable, Hashable {
		case user(Profile.Network.AccountForDisplay)
		case external(AccountAddress, approved: Bool)

		var address: AccountAddress {
			switch self {
			case let .user(account):
				return account.address
			case let .external(address, _):
				return address
			}
		}
	}

	public struct Transfer: Sendable, Identifiable, Hashable {
		public var id: AccountAction { action }

		public let action: AccountAction
		public var metadata: ResourceMetadata

		public init(
			action: AccountAction,
			metadata: ResourceMetadata
		) {
			self.action = action
			self.metadata = metadata
		}
	}

	public struct ResourceMetadata: Sendable, Hashable {
		public let name: String?
		public let thumbnail: URL?
		public var type: ResourceType?
		public var guaranteedAmount: BigDecimal?
		public var dollarAmount: BigDecimal?

		public init(
			name: String?,
			thumbnail: URL?,
			type: ResourceType? = nil,
			guaranteedAmount: BigDecimal? = nil,
			dollarAmount: BigDecimal? = nil
		) {
			self.name = name
			self.thumbnail = thumbnail
			self.type = type
			self.guaranteedAmount = guaranteedAmount
			self.dollarAmount = dollarAmount
		}
	}
}

extension TransactionReview.State {
	public static let mock0 = Self(message: "Royalties claim",
	                               withdrawing: .init(accounts: [.mockWithdraw0], showCustomizeGuarantees: false),
	                               dAppsUsed: .init(isExpanded: false, dApps: []),
	                               depositing: .init(accounts: [.mockDeposit1], showCustomizeGuarantees: true),
	                               presenting: .init(dApps: [.mock1, .mock0]),
	                               networkFee: .init(fee: 0.1, isCongested: false))

	public static let mock1 = Self(message: "Royalties claim",
	                               withdrawing: .init(accounts: [.mockWithdraw0, .mockWithdraw1], showCustomizeGuarantees: false),
	                               dAppsUsed: .init(isExpanded: true, dApps: [.mock3, .mock2, .mock1]),
	                               depositing: .init(accounts: [.mockDeposit2], showCustomizeGuarantees: true),
	                               presenting: .init(dApps: [.mock1, .mock0]),
	                               networkFee: .init(fee: 0.2, isCongested: true))
}

extension TransactionReview.Dapp {
	public static let mock0 = Self(id: .deadbeef32Bytes,
	                               metadata: .init(name: "Collabofi User Badge", thumbnail: nil, description: nil))

	public static let mock1 = Self(id: .deadbeef64Bytes,
	                               metadata: .init(name: "Oh Babylon Founder NFT", thumbnail: nil, description: nil))

	public static let mock2 = Self(id: "deadbeef64Bytes", metadata: nil)

	public static let mock3 = Self(id: "deadbeef32Bytes", metadata: nil)
}

extension TransactionReviewAccount.State {
	public static let mockWithdraw0 = Self(account: .mockUser0, transfers: [.mock0, .mock1])

	public static let mockWithdraw1 = Self(account: .mockUser1, transfers: [.mock1, .mock3, .mock4])

	public static let mockWithdraw2 = Self(account: .mockUser0, transfers: [.mock1, .mock3])

	public static let mockDeposit1 = Self(account: .mockExternal0, transfers: [.mock1, .mock3, .mock4])

	public static let mockDeposit2 = Self(account: .mockExternal1, transfers: [.mock1, .mock3])
}

extension TransactionReview.Account {
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

extension ComponentAddress {
	public static let mock0 = Self(address: "account_tdx_b_k591p8y440g69dlqnuzghu84e84ak088fah9u6ay440g6pzq8y4")
	public static let mock1 = Self(address: "account_tdx_b_e84ak088fah9u6ad6j9dlqnuz84e84ak088fau6ad6j9dlqnuzk")
	public static let mock2 = Self(address: "account_tdx_b_1pzq8y440g6nc4vuz0ghu84e84ak088fah9u6ad6j9dlqnuzk59")
}

extension ResourceAddress {
	public static let mock0 = Self(address: "resource_tdx_b_1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq8z96qp")
	public static let mock1 = Self(address: "resource_tdx_b_1qre9sv98scqut4k9g3j6kxuvscczv0lzumefwgwhuf6qdu4c3r")
}

extension URL {
	static let mock = URL(string: "test")!
}

extension TransactionReview.Transfer {
	public static let mock0 = Self(action: .mock0,
	                               metadata: .init(name: "TSLA",
	                                               thumbnail: .mock,
	                                               type: .fungible,
	                                               guaranteedAmount: 1.0188,
	                                               dollarAmount: 301.91))

	public static let mock1 = Self(action: .mock1,
	                               metadata: .init(name: "XRD",
	                                               thumbnail: .mock,
	                                               type: .fungible,
	                                               dollarAmount: 301.91))

	public static let mock2 = Self(action: .mock2,
	                               metadata: .init(name: "PXL",
	                                               thumbnail: .mock,
	                                               type: .fungible,
	                                               guaranteedAmount: 5.10))

	public static let mock3 = Self(action: .mock3,
	                               metadata: .init(name: "PXL",
	                                               thumbnail: .mock,
	                                               type: .fungible))

	public static let mock4 = Self(action: .mock4,
	                               metadata: .init(name: "Block 14F5",
	                                               thumbnail: .mock,
	                                               type: .nonFungible))
}

extension AccountAction {
	public static let mock0 = Self(componentAddress: .mock0,
	                               resourceAddress: .mock0,
	                               amount: 1.0396)

	public static let mock1 = Self(componentAddress: .mock1,
	                               resourceAddress: .mock1,
	                               amount: 500)

	public static let mock2 = Self(componentAddress: .mock0,
	                               resourceAddress: .mock1,
	                               amount: 5.123)

	public static let mock3 = Self(componentAddress: .mock1,
	                               resourceAddress: .mock0,
	                               amount: 500)

	public static let mock4 = Self(componentAddress: .mock0,
	                               resourceAddress: .mock0,
	                               amount: 1)
}

public func decodeActions() {
	guard let data = fullResponse.data(using: .utf8) else {
		print("decodeActions failed data")
		return
	}

	print("Data: \(String(data: data, encoding: .utf8) ?? "nil")")

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
