import Address
import Asset

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
	typealias FetchAssets = @Sendable (Address) async throws -> [[any Asset]]
}
