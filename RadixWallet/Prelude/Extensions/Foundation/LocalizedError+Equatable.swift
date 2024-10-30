
extension LocalizedError where Self: Equatable {
	static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.errorDescription == rhs.errorDescription
	}
}
