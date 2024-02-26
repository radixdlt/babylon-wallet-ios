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
				order(lhs: lhsValue.amount, rhs: rhsValue.amount, minValue: .init(.min()))
			} else {
				// Else sort alphabetically by title, or failing that, address
				order(lhs: lhsValue.title, rhs: rhsValue.title) {
					lhsValue.address.address < rhsValue.address.address
				}
			}
		case let (.nonFungible(lhsValue), .nonFungible(rhsValue)):
			if lhsValue.id.resourceAddress() == rhsValue.id.resourceAddress() {
				lhsValue.id.localId().toUserFacingString() < rhsValue.id.localId().toUserFacingString()
			} else {
				lhsValue.id.resourceAddress().asStr() < rhsValue.id.resourceAddress().asStr()
			}
		case let (.lsu(lhsValue), .lsu(rhsValue)):
			order(lhs: lhsValue.validatorName, rhs: rhsValue.validatorName) {
				// If it's the same validator (name), sort by the resource
				if lhsValue.resource == rhsValue.resource {
					// If it's the same resource, sort by the amount
					order(lhs: lhsValue.amount, rhs: rhsValue.amount, minValue: .init(.min()))
				} else {
					// Else sort alphabetically by resource title, or failing that, address
					order(lhs: lhsValue.resource.metadata.title, rhs: rhsValue.resource.metadata.title) {
						lhsValue.resource.resourceAddress.address < rhsValue.resource.resourceAddress.address
					}
				}
			}
		default:
			lhs.priority < rhs.priority
		}
	}

	private var priority: Int {
		switch self {
		case .fungible:
			0
		case .nonFungible:
			1
		case .lsu:
			2
		}
	}
}

// MARK: - ResourceBalance.Amount + Comparable
extension ResourceBalance.Amount: Comparable {
	public static func < (lhs: ResourceBalance.Amount, rhs: ResourceBalance.Amount) -> Bool {
		// If RETDecimal were comparable:
//		order(lhs: lhs.amount, rhs: rhs.amount) {
//			order(lhs: lhs.guaranteed, rhs: rhs.guaranteed, minValue: 0)
//		}

		if lhs.amount == rhs.amount {
			lhs.guaranteed ?? 0 < rhs.guaranteed ?? 0
		} else {
			lhs.amount < rhs.amount
		}
	}

	public static let zero = ResourceBalance.Amount(0)
}

private func order<W: Comparable>(lhs: W?, rhs: W?, tieBreak: () -> Bool) -> Bool {
	switch (lhs, rhs) {
	case let (lhsValue?, rhsValue?):
		if lhs == rhs {
			tieBreak()
		} else {
			lhsValue < rhsValue
		}
	case (nil, _?):
		true
	case (_?, nil):
		false
	case (nil, nil):
		tieBreak()
	}
}

private func order<W: Comparable>(lhs: W?, rhs: W?, minValue: W) -> Bool {
	lhs ?? minValue < rhs ?? minValue
}