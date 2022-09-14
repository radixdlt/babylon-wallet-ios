import ComposableArchitecture

// MARK: - AssetSection
/// Namespace for AssetSectionFeature
public extension Home {
	enum AssetSection {}
}

public extension Home.AssetSection {
	// MARK: State
	struct State: Equatable, Identifiable {
		public let id = UUID()
		public var assets: IdentifiedArrayOf<Home.AssetRow.State>

		public init(
			assets: IdentifiedArrayOf<Home.AssetRow.State>
		) {
			self.assets = assets
		}
	}
}
