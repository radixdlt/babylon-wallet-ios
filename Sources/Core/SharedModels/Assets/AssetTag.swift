import Foundation

// MARK: - AssetTag
public enum AssetTag: Hashable, Sendable, Codable {
	case officialRadix
	case custom(String)
}

extension AssetTag {
	public init(_ customString: String) {
		self = .custom(customString)
	}
}
