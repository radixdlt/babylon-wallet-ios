import Foundation

public extension StringProtocol {
	var isBlank: Bool {
		trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
	}

	func trimmed() -> String {
		trimmingCharacters(in: .whitespaces)
	}

	func lines() -> Int {
		split(separator: "\n", omittingEmptySubsequences: false).count
	}
}

public extension Optional where Wrapped: StringProtocol {
	var isNilOrEmpty: Bool {
		self == nil || self?.isEmpty == true
	}

	var isNilOrBlank: Bool {
		self == nil || self?.isBlank == true
	}
}
