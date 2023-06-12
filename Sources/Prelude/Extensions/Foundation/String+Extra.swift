import Foundation

extension StringProtocol {
	public var isBlank: Bool {
		trimWhitespacesAndNewLines().isEmpty
	}

	/// Trims whitespaces
	public func trimmingWhitespace() -> String {
		trimmingCharacters(in: .whitespaces)
	}

	/// Trims newlines
	public func trimmingNewlines() -> String {
		trimmingCharacters(in: .newlines)
	}

	/// Trims whitespaces and newlines
	public func trimmingWhitespacesAndNewlines() -> String {
		trimmingCharacters(in: .whitespacesAndNewlines)
	}

	public func lines() -> Int {
		split(separator: "\n", omittingEmptySubsequences: false).count
	}

	public var nilIfBlank: Self? {
		isBlank ? nil : self
	}
}

extension Optional where Wrapped: StringProtocol {
	public var isNilOrBlank: Bool {
		self == nil || self?.isBlank == true
	}
}

extension String {
	public var isEmailAddress: Bool {
		// Adapted from https://www.swiftbysundell.com/articles/validating-email-addresses

		let detector = try? NSDataDetector(
			types: NSTextCheckingResult.CheckingType.link.rawValue
		)

		let range = NSRange(
			self.startIndex ..< self.endIndex,
			in: self
		)

		let matches = detector?.matches(
			in: self,
			options: [],
			range: range
		)

		// We only want our string to contain a single email
		// address, so if multiple matches were found, then
		// we fail our validation process and return nil:
		guard let match = matches?.first, matches?.count == 1 else {
			return false
		}

		// Verify that the found link points to an email address,
		// and that its range covers the whole input string:
		guard match.url?.scheme == "mailto", match.range == range else {
			return false
		}

		return true
	}
}
