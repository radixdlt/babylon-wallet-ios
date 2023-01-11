extension BitArray: Equatable {
	public static func == (left: Self, right: Self) -> Bool {
		guard left._count == right._count else { return false }
		return left._storage == right._storage
	}
}
