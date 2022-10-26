import Asset
import BigInt
import ComposableArchitecture
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

public extension DependencyValues {
	var assetFetcher: AssetFetcher {
		get { self[AssetFetcher.self] }
		set { self[AssetFetcher.self] = newValue }
	}
}
