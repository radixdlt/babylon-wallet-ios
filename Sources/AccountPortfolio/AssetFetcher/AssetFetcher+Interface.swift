import Asset
@preconcurrency import BigInt
import Profile

// MARK: - AssetFetcher
public struct AssetFetcher {
	public var fetchAssets: FetchAssets

	public init(
		fetchAssets: @escaping FetchAssets
	) {
		self.fetchAssets = fetchAssets
	}
}

// MARK: AssetFetcher.FetchAssets
public extension AssetFetcher {
	typealias FetchAssets = @Sendable (AccountAddress) async throws -> OwnedAssets
}

// MARK: - OwnedAssets
public struct OwnedAssets: Sendable, Hashable {
	//    public let ownedAssets: [OwnedAsset]
	public let ownedFungibleTokens: [OwnedFungibleToken]
	public let ownedNonFungibleTokens: [OwnedNonFungibleToken]
	public init(ownedFungibleTokens: [OwnedFungibleToken], ownedNonFungibleTokens: [OwnedNonFungibleToken]) {
		self.ownedFungibleTokens = ownedFungibleTokens
		self.ownedNonFungibleTokens = ownedNonFungibleTokens
	}
}

public extension OwnedAssets {
	//    var ownedFungibleTokens: [OwnedFungibleToken] {
	//        ownedAssets.compactMap { $0.ownedFungibleToken }
	//    }
	//    var ownedNonFungibleTokens: [OwnedNonFungibleToken] {
	//        ownedAssets.compactMap { $0.ownedNonFungibleToken }
	//    }

	var fungibleTokenContainers: [FungibleTokenContainer] {
		ownedFungibleTokens.map {
			.init(asset: $0.token, amount: $0.amount, worth: nil)
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
	public let amount: BigUInt
	public let token: FungibleToken
}

// MARK: - OwnedNonFungibleToken
public struct OwnedNonFungibleToken: Sendable, Hashable {
	public let owner: AccountAddress
	public let nonFungibleIDS: [String]
	public let token: NonFungibleToken
}

// MARK: - SimpleOwnedAssets
public struct SimpleOwnedAssets: Sendable, Hashable {
	//    public let simpleOwnedAssets: [SimpleOwnedAsset]
	public let simpleOwnedFungibleTokens: [SimpleOwnedFungibleToken]
	public let simpleOwnedNonFungibleTokens: [SimpleOwnedNonFungibleToken]
	public init(simpleOwnedFungibleTokens: [SimpleOwnedFungibleToken], simpleOwnedNonFungibleTokens: [SimpleOwnedNonFungibleToken]) {
		self.simpleOwnedFungibleTokens = simpleOwnedFungibleTokens
		self.simpleOwnedNonFungibleTokens = simpleOwnedNonFungibleTokens
	}
}

public extension SimpleOwnedAssets {
	//    var simpleOwnedFungibleTokens: [SimpleOwnedFungibleToken] {
	//        simpleOwnedAssets.compactMap { $0.simpleOwnedFungibleToken }
	//    }
	//    var simpleOwnedNonFungibleTokens: [SimpleOwnedNonFungibleToken] {
	//        simpleOwnedAssets.compactMap { $0.simpleOwnedNonFungibleToken }
	//    }
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
	public let amount: BigUInt
	public let tokenResourceAddress: String
}

// MARK: - SimpleOwnedNonFungibleToken
public struct SimpleOwnedNonFungibleToken: Sendable, Hashable {
	public let owner: AccountAddress
	public let nonFungibleIDS: [String]
	public let tokenResourceAddress: String
}
