import Foundation

extension InteractionReview {
	enum DisplayMode: Hashable {
		case detailed
		case raw(manifest: String)

		var rawManifest: String? {
			guard case let .raw(manifest) = self else { return nil }
			return manifest
		}
	}
}
