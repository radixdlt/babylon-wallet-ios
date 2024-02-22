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
	let manifestClass: GatewayAPI.ManifestClass?
	let withdrawals: [ResourceBalance]
	let deposits: [ResourceBalance]
	let depositSettingsUpdated: Bool
}

// MARK: - ResourceBalance + Comparable
extension ResourceBalance: Comparable {
	public static func < (lhs: ResourceBalance, rhs: ResourceBalance) -> Bool {
		switch (lhs, rhs) {
		case let (.fungible(lhsValue), .fungible(rhsValue)):
			if lhsValue.address == rhsValue.address {
				// If it's the same resource, sort by the amount
				lhsValue.amount ?? .init(.min()) < rhsValue.amount ?? .init(.min())
			} else {
				// Else sort alphabetically by title, or failing that, address
				switch (lhsValue.title, rhsValue.title) {
				case let (lhsTitle?, rhsTitle?):
					lhsTitle < rhsTitle
				case (nil, _?):
					true
				case (_?, nil):
					false
				case (nil, nil):
					lhsValue.address.address < rhsValue.address.address
				}
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

// MARK: - ResourceBalance.Amount + Comparable
extension ResourceBalance.Amount: Comparable {
	public static func < (lhs: ResourceBalance.Amount, rhs: ResourceBalance.Amount) -> Bool {
		if lhs.amount == rhs.amount {
			lhs.guaranteed ?? 0 < rhs.guaranteed ?? 0
		} else {
			lhs.amount < rhs.amount
		}
	}

	public static let zero = ResourceBalance.Amount(0)
}
