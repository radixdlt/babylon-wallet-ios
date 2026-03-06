// MARK: - OnLedgerTag
enum OnLedgerTag: Hashable, Codable, Comparable {
	case officialRadix
	case custom(NonEmptyString)
}

extension OnLedgerTag {
	init(_ customString: NonEmptyString) {
		self = .custom(customString)
	}
}
