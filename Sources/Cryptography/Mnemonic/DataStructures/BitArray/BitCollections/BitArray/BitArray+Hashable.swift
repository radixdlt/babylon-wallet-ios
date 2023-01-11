extension BitArray: Hashable {
	public func hash(into hasher: inout Hasher) {
		hasher.combine(_count)
		for word in _storage {
			hasher.combine(word)
		}
	}
}
