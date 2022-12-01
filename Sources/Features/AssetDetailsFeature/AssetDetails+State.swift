import Foundation

// MARK: - AssetDetails.State
public extension AssetDetails {
	struct State: Equatable {
		public init() {}
	}
}

#if DEBUG
public extension AssetDetails.State {
	static let previewValue: Self = .init()
}
#endif
