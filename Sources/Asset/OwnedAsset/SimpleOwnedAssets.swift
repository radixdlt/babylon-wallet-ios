import BigInt
import Foundation
import Profile

// MARK: - SimpleOwnedAssets
public struct SimpleOwnedAssets: Sendable, Hashable {
	public let simpleOwnedFungibleTokens: [SimpleOwnedFungibleToken]
	public let simpleOwnedNonFungibleTokens: [SimpleOwnedNonFungibleToken]
	public init(simpleOwnedFungibleTokens: [SimpleOwnedFungibleToken], simpleOwnedNonFungibleTokens: [SimpleOwnedNonFungibleToken]) {
		self.simpleOwnedFungibleTokens = simpleOwnedFungibleTokens
		self.simpleOwnedNonFungibleTokens = simpleOwnedNonFungibleTokens
	}
}

public extension SimpleOwnedAssets {
	var assets: [SimpleOwnedAsset] {
		simpleOwnedFungibleTokens.map { SimpleOwnedAsset.simpleOwnedFungibleToken($0) } +
			simpleOwnedNonFungibleTokens.map { SimpleOwnedAsset.simpleOwnedNonFungibleToken($0) }
	}
}

// MARK: - SimpleOwnedAsset
public enum SimpleOwnedAsset: Sendable, Hashable {
	case simpleOwnedFungibleToken(SimpleOwnedFungibleToken)
	case simpleOwnedNonFungibleToken(SimpleOwnedNonFungibleToken)
}

public extension SimpleOwnedAsset {
	var simpleOwnedFungibleToken: SimpleOwnedFungibleToken? {
		guard case let .simpleOwnedFungibleToken(token) = self else {
			return nil
		}
		return token
	}

	var simpleOwnedNonFungibleToken: SimpleOwnedNonFungibleToken? {
		guard case let .simpleOwnedNonFungibleToken(token) = self else {
			return nil
		}
		return token
	}
}

// MARK: - SimpleOwnedFungibleToken
public struct SimpleOwnedFungibleToken: Sendable, Hashable {
	public let owner: AccountAddress
	public let amountInAttos: BigUInt
	public let tokenResourceAddress: String

	public init(owner: AccountAddress, amountInAttos: BigUInt, tokenResourceAddress: String) {
		self.owner = owner
		self.amountInAttos = amountInAttos
		self.tokenResourceAddress = tokenResourceAddress
	}
}

// MARK: - SimpleOwnedNonFungibleToken
public struct SimpleOwnedNonFungibleToken: Sendable, Hashable {
	public let owner: AccountAddress
	public let nonFungibleIDS: [String]
	public let tokenResourceAddress: String

	public init(owner: AccountAddress, nonFungibleIDS: [String], tokenResourceAddress: String) {
		self.owner = owner
		self.nonFungibleIDS = nonFungibleIDS
		self.tokenResourceAddress = tokenResourceAddress
	}
}
