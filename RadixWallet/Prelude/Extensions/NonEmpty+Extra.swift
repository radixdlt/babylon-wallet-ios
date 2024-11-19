// MARK: - NonEmpty + Sendable
extension NonEmpty: @unchecked Sendable where Element: Sendable {}

extension NonEmptyString {
	init?(maybeString: String?) {
		guard let string = maybeString else {
			return nil
		}
		self.init(rawValue: string)
	}
}
