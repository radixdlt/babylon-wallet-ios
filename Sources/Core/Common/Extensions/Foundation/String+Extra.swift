import Foundation

public extension String {
	func trimmed() -> Self {
		trimmingCharacters(in: .whitespaces)
	}

	func lines() -> Int {
		split(separator: "\n", omittingEmptySubsequences: false).count
	}
}
