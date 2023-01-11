import Foundation

public extension StringProtocol {
	func trimmed() -> String {
		trimmingCharacters(in: .whitespaces)
	}

	func lines() -> Int {
		split(separator: "\n", omittingEmptySubsequences: false).count
	}
}
