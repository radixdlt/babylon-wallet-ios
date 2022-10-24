import Foundation

// MARK: ImportProfile.State
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
