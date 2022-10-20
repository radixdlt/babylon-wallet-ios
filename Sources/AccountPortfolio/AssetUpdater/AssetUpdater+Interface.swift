import Asset
import Common
import Profile

// MARK: - AssetUpdater
public struct AssetUpdater {
	public var updateAssets: UpdateAssets
	public var updateSingleAsset: UpdateSingleAsset

	public init(
		updateAssets: @escaping UpdateAssets,
		updateSingleAsset: @escaping UpdateSingleAsset
	) {
		self.updateAssets = updateAssets
		self.updateSingleAsset = updateSingleAsset
	}
}

// MARK: - Typealias
public extension AssetUpdater {
	typealias UpdateAssets = @Sendable ([[any Asset]], FiatCurrency) async throws -> AccountPortfolio
	typealias UpdateSingleAsset = @Sendable (any Asset, FiatCurrency) async throws -> any AssetContainer
}
