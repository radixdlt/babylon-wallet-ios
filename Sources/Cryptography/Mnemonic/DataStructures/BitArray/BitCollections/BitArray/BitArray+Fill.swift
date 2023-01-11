public extension BitArray {
	mutating func fill(with value: Bool = true) {
		fill(in: Range(uncheckedBounds: (0, count)), with: value)
	}

	mutating func fill(in range: Range<Int>, with value: Bool = true) {
		_update { handle in
			if value {
				handle.fill(in: range)
			} else {
				handle.clear(in: range)
			}
		}
	}
}
