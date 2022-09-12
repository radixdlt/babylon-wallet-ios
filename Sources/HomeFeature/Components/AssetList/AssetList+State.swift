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
		public let assets: IdentifiedArrayOf<Home.AssetRow.State>

		public init(
			assets: IdentifiedArrayOf<Home.AssetRow.State>
		) {
			self.assets = assets
		}
	}
}
