import Foundation

extension StringProtocol {
	public var isBlank: Bool {
		trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
	}

	public func trimmed() -> String {
		trimmingCharacters(in: .whitespaces)
	}

	public func lines() -> Int {
		split(separator: "\n", omittingEmptySubsequences: false).count
	}

	public var nilIfEmpty: Self? {
		isEmpty ? nil : self
	}

	public var nilIfBlank: Self? {
		isBlank ? nil : self
	}
}

extension Optional where Wrapped: StringProtocol {
	public var isNilOrEmpty: Bool {
		self == nil || self?.isEmpty == true
	}

	public var isNilOrBlank: Bool {
		self == nil || self?.isBlank == true
	}
}
