import ComposableArchitecture

// MARK: - Section
/// Namespace for Section
public extension AssetList {
	enum Section {}
}

public extension AssetList.Section {
	// MARK: State
	struct State: Equatable, Identifiable {
		public let id = UUID()
		public var assets: IdentifiedArrayOf<AssetList.Row.State>

		public init(
			assets: IdentifiedArrayOf<AssetList.Row.State>
		) {
			self.assets = assets
		}
	}
}
