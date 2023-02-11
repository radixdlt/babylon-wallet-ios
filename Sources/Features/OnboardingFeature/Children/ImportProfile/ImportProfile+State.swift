import FeaturePrelude

// MARK: - ImportProfile.State
extension ImportProfile {
	public struct State: Equatable & Sendable {
		public var isDisplayingFileImporter = false

		public init(
			isDisplayingFileImporter: Bool = false
		) {
			self.isDisplayingFileImporter = isDisplayingFileImporter
		}
	}
}

#if DEBUG
extension ImportProfile.State {
	public static let previewValue: Self = .init()
}
#endif
