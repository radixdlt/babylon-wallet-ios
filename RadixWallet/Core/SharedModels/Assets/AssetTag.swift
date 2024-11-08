// MARK: - AssetTag
enum AssetTag: Hashable, Sendable, Codable {
	case officialRadix
	case custom(NonEmptyString)
}

extension AssetTag {
	init(_ customString: NonEmptyString) {
		self = .custom(customString)
	}
}
