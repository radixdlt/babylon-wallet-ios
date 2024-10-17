// MARK: - ImageAsset + Equatable
extension ImageAsset: Equatable {
	static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.name == rhs.name
	}
}

// MARK: - ImageAsset + Hashable
extension ImageAsset: Hashable {
	func hash(into hasher: inout Hasher) {
		hasher.combine(name)
	}
}
