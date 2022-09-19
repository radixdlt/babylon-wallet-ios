import ComposableArchitecture

// MARK: - Section
/// Namespace for Section
public extension AssetList {
	enum Section {}
}

public extension AssetList.Section {
	// MARK: State
	struct State: Equatable, Identifiable {
		public let id: Int
		public var assets: IdentifiedArrayOf<AssetList.Row.State>

		public init(
			id: Int,
			assets: IdentifiedArrayOf<AssetList.Row.State>
		) {
			self.id = id
			self.assets = assets
		}
	}
}
