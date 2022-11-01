import BigInt
import Foundation
import Profile

// MARK: - OwnedAssets
public struct OwnedAssets: Sendable, Hashable {
	public let ownedFungibleTokens: [OwnedFungibleToken]
	public let ownedNonFungibleTokens: [OwnedNonFungibleToken]

	public init(ownedFungibleTokens: [OwnedFungibleToken], ownedNonFungibleTokens: [OwnedNonFungibleToken]) {
		self.ownedFungibleTokens = ownedFungibleTokens
		self.ownedNonFungibleTokens = ownedNonFungibleTokens
	}
}

public extension OwnedAssets {
	var fungibleTokenContainers: [FungibleTokenContainer] {
		ownedFungibleTokens.map {
			.init(asset: $0.token, amountInAttos: $0.amountInAttos, worth: nil)
		}
	}

	var nonFungibleTokenContainers: [NonFungibleTokenContainer] {
		ownedNonFungibleTokens.map {
			.init(asset: $0.token, metadata: [[:]])
		}
	}

	var assets: [OwnedAsset] {
		ownedFungibleTokens.map { OwnedAsset.ownedFungibleToken($0) } +
			ownedNonFungibleTokens.map { OwnedAsset.ownedNonFungibleToken($0) }
	}

	static let empty = Self(ownedFungibleTokens: [], ownedNonFungibleTokens: [])
}

// MARK: - OwnedAsset
public enum OwnedAsset: Sendable, Hashable {
	case ownedFungibleToken(OwnedFungibleToken)
	case ownedNonFungibleToken(OwnedNonFungibleToken)
}

public extension OwnedAsset {
	var ownedFungibleToken: OwnedFungibleToken? {
		guard case let .ownedFungibleToken(ownedFungibleToken) = self else {
			return nil
		}
		return ownedFungibleToken
	}

	var ownedNonFungibleToken: OwnedNonFungibleToken? {
		guard case let .ownedNonFungibleToken(ownedNonFungibleToken) = self else {
			return nil
		}
		return ownedNonFungibleToken
	}
}

// MARK: - OwnedFungibleToken
public struct OwnedFungibleToken: Sendable, Hashable {
	public let owner: AccountAddress
	public let amountInAttos: BigUInt
	public let token: FungibleToken

	public init(owner: AccountAddress, amountInAttos: BigUInt, token: FungibleToken) {
		self.owner = owner
		self.amountInAttos = amountInAttos
		self.token = token
	}
}

// MARK: - OwnedNonFungibleToken
public struct OwnedNonFungibleToken: Sendable, Hashable {
	public let owner: AccountAddress
	public let nonFungibleIDS: [String]
	public let token: NonFungibleToken

	public init(owner: AccountAddress, nonFungibleIDS: [String], token: NonFungibleToken) {
		self.owner = owner
		self.nonFungibleIDS = nonFungibleIDS
		self.token = token
	}
}
