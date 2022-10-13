import Foundation

public extension String {
	func trimmed() -> Self {
		trimmingCharacters(in: .whitespaces)
	}
}
