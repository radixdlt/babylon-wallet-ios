// MARK: - ImageAsset + Equatable
extension ImageAsset: Equatable {
	public static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.name == rhs.name
	}
}

// MARK: - ImageAsset + Hashable
extension ImageAsset: Hashable {
	public func hash(into hasher: inout Hasher) {
		hasher.combine(name)
	}
}
