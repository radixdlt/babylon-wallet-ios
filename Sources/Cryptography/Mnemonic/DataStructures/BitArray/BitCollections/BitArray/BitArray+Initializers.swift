// Modifications: Removed bitSet initializer

public extension BitArray {
	init<I: BinaryInteger>(bitPattern value: I) {
		let words = value.words.map { _Word($0) }
		let count = value.bitWidth
		self.init(_storage: words, count: count)
	}
}
