import Foundation

// MARK: - TransactionHistoryClient
public struct TransactionHistoryClient: Sendable, DependencyKey {
	public var getTransactionHistory: GetTransactionHistory
}

// MARK: TransactionHistoryClient.GetTransactionHistory
extension TransactionHistoryClient {
	public typealias GetTransactionHistory = @Sendable (_ account: AccountAddress, _ cursor: String?) async throws -> TransactionHistoryResponse
}

// MARK: - TransactionHistoryResponse
public struct TransactionHistoryResponse: Sendable, Hashable {
	public let cursor: String?
	public let items: [TransactionHistoryItem]
}

// MARK: - TransactionHistoryItem
public struct TransactionHistoryItem: Sendable, Hashable {
	let time: Date
	let message: String?
	let actions: [Action]
	let manifestClass: GatewayAPI.ManifestClass?

	enum Action: Sendable, Hashable {
		case withdrawal(ResourceBalance)
		case deposit(ResourceBalance)
		case settings
	}
}

// MARK: - TransactionHistoryItem.Action + Comparable
extension TransactionHistoryItem.Action: Comparable {
	public static func < (lhs: TransactionHistoryItem.Action, rhs: TransactionHistoryItem.Action) -> Bool {
		switch (lhs, rhs) {
		case let (.withdrawal(lhsBalance), .withdrawal(rhsBalance)), let (.deposit(lhsBalance), .deposit(rhsBalance)):
			lhsBalance < rhsBalance
		default:
			lhs.ordinal < rhs.ordinal
		}
	}

	private var ordinal: Int {
		switch self {
		case .withdrawal:
			0
		case .deposit:
			1
		case .settings:
			2
		}
	}
}

// MARK: - ResourceBalance + Comparable
extension ResourceBalance: Comparable {
	public static func < (lhs: ResourceBalance, rhs: ResourceBalance) -> Bool {
		switch (lhs, rhs) {
		case let (.fungible(lhsValue), .fungible(rhsValue)):
			switch (lhsValue.amount, rhsValue.amount) {
			case let (lhsAmount?, rhsAmount?):
				lhsAmount.amount < rhsAmount.amount
			case (nil, _?):
				true
			case (_?, nil):
				false
			case (nil, nil):
				lhsValue.address.address < rhsValue.address.address
			}
		case let (.nonFungible(lhsValue), .nonFungible(rhsValue)):
			if lhsValue.id.resourceAddress() == rhsValue.id.resourceAddress() {
				lhsValue.id.localId().toUserFacingString() < rhsValue.id.localId().toUserFacingString()
			} else {
				lhsValue.id.resourceAddress().asStr() < rhsValue.id.resourceAddress().asStr()
			}
		case (.fungible, .nonFungible):
			true
		case (.nonFungible, .fungible):
			false
		}
	}
}
