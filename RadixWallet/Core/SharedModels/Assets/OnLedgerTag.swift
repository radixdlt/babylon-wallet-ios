// MARK: - OnLedgerTag
enum OnLedgerTag: Hashable, Sendable, Codable, Comparable {
	case officialRadix
	case custom(NonEmptyString)
}

extension OnLedgerTag {
	init(_ customString: NonEmptyString) {
		self = .custom(customString)
	}
}
