import Foundation

// MARK: - PreAuthorizationFailure
enum PreAuthorizationFailure: Sendable, LocalizedError, Equatable {
	case failedToGetPreview(FailedToGetPreview)

	var errorDescription: String? {
		switch self {
		case let .failedToGetPreview(error):
			error.localizedDescription
		}
	}
}

// MARK: PreAuthorizationFailure.FailedToGetPreview
extension PreAuthorizationFailure {
	enum FailedToGetPreview: Sendable, LocalizedError, Equatable {
		case failedToAnalyse(Error)

		var errorDescription: String? {
			switch self {
			case let .failedToAnalyse(error):
				"Failed to analyse PreAuthorization Preview: \(error.localizedDescription)"
			}
		}
	}
}
