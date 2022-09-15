import ComposableArchitecture

// MARK: - AssetSection
/// Namespace for AssetSectionFeature
public extension AccountDetails {
	enum AssetSection {}
}

public extension AccountDetails.AssetSection {
	// MARK: State
	struct State: Equatable, Identifiable {
		public let id = UUID()
		public var assets: IdentifiedArrayOf<AccountDetails.AssetRow.State>

		public init(
			assets: IdentifiedArrayOf<AccountDetails.AssetRow.State>
		) {
			self.assets = assets
		}
	}
}
