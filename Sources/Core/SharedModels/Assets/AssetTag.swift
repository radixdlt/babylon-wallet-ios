import Foundation
import NonEmpty

// MARK: - AssetTag
public enum AssetTag: Hashable, Sendable, Codable {
	case officialRadix
	case custom(NonEmptyString)
}

extension AssetTag {
	public init(_ customString: NonEmptyString) {
		self = .custom(customString)
	}
}
