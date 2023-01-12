import FeaturePrelude

// MARK: - ImportProfile.State
public extension ImportProfile {
	struct State: Equatable {
		public var isDisplayingFileImporter = false

		public init(
			isDisplayingFileImporter: Bool = false
		) {
			self.isDisplayingFileImporter = isDisplayingFileImporter
		}
	}
}

#if DEBUG
public extension ImportProfile.State {
	static let previewValue: Self = .init()
}
#endif
