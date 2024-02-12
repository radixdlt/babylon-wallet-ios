import Foundation

// MARK: - AssetsTransfersTransactionPrototype
// NOT FINAL, just a sketch, probably wrong...
public struct AssetsTransfersTransactionPrototype {
	public let fromAccount: AccountAddress
	public let transfers: IdentifiedArrayOf<AssetsTransfersToRecipient>
}

// MARK: - AssetsTransfersToRecipient
// NOT FINAL, just a sketch, probably wrong...
public struct AssetsTransfersToRecipient: Identifiable {
	public let recipient: AssetsTransfersRecipient
	public let fungibles: [FungiblePositiveAmount]
	public let nonFungibles: [NonFungibleGlobalId]

	public var id: AssetsTransfersRecipient {
		recipient
	}
}

// MARK: - FungiblePositiveAmount
public struct FungiblePositiveAmount {
	public let resourceAddress: ResourceAddress
	public let amount: RETDecimal
}

// MARK: - AssetsTransfersRecipient
public enum AssetsTransfersRecipient: Hashable, Identifiable {
	case myOwnAccount(Profile.Network.Account)
	case foreignAccount(AccountAddress)
	public var id: AccountAddress {
		switch self {
		case let .foreignAccount(address): address
		case let .myOwnAccount(account): account.address
		}
	}
}
