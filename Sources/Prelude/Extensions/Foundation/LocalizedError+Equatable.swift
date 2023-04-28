import Foundation

extension LocalizedError where Self: Equatable {
	public static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.errorDescription == rhs.errorDescription
	}
}
