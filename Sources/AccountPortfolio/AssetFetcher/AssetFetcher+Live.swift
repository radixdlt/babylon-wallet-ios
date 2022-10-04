import Asset

public extension AssetFetcher {
	static let live = Self(
		fetchAssets: { _ in
			// TODO: replace with real implementation when API is ready
			AssetGenerator.mockAssets
		}
	)
}
