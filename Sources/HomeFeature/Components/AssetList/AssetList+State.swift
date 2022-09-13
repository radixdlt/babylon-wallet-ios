import Common
import ComposableArchitecture

// MARK: - AssetList
/// Namespace for AssetListFeature
public extension Home {
	enum AssetList {}
}

public extension Home.AssetList {
	// MARK: State
	struct State: Equatable {
		public var xrdToken: Home.AssetRow.State?
		public var assets: IdentifiedArrayOf<Home.AssetRow.State>

		public init(
			xrdToken: Home.AssetRow.State?,
			assets: IdentifiedArrayOf<Home.AssetRow.State>
		) {
			self.xrdToken = xrdToken
			self.assets = assets
		}
	}
}
