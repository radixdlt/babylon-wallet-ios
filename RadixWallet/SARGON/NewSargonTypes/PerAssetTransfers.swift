import Foundation

// MARK: - AssetsTransfersRecipient
public enum AssetsTransfersRecipient: Sendable, Hashable, Identifiable {
	case myOwnAccount(Profile.Network.Account)
	case foreignAccount(AccountAddress)
	public var id: AccountAddress {
		switch self {
		case let .foreignAccount(address): address
		case let .myOwnAccount(account): account.address
		}
	}
}

// MARK: - PerAssetFungibleResource
public struct PerAssetFungibleResource: Sendable, Hashable {
	public let resourceAddress: ResourceAddress
	public let divisibility: UInt8?
}

// MARK: - PerAssetFungibleTransfer
public struct PerAssetFungibleTransfer: Sendable, Hashable {
	public let useTryDepositOrAbort: Bool
	public let amount: Decimal192
	public let recipient: AssetsTransfersRecipient
}

// MARK: - PerAssetTransfersOfFungibleResource
public struct PerAssetTransfersOfFungibleResource: Sendable, Hashable {
	public let resource: PerAssetFungibleResource
	public let transfers: [PerAssetFungibleTransfer]
}

// MARK: - PerAssetNonFungibleTransfer
public struct PerAssetNonFungibleTransfer: Sendable, Hashable {
	public let useTryDepositOrAbort: Bool
	public let nonFungibleLocalIds: [NonFungibleLocalId]
	public let recipient: AssetsTransfersRecipient
}

// MARK: - PerAssetTransfersOfNonFungibleResource
public struct PerAssetTransfersOfNonFungibleResource: Sendable, Hashable {
	public let resource: ResourceAddress
	public let transfers: [PerAssetNonFungibleTransfer]
}

// MARK: - PerAssetTransfers
public struct PerAssetTransfers: Sendable, Hashable {
	public let fromAccount: AccountAddress
	public let fungibleResources: [PerAssetTransfersOfFungibleResource]
	public let nonFungibleResources: [PerAssetTransfersOfNonFungibleResource]
}
