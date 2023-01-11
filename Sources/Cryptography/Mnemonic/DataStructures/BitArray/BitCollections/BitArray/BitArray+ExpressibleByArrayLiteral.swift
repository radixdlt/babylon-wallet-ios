extension BitArray: ExpressibleByArrayLiteral {
	public init(arrayLiteral elements: Bool...) {
		self.init(elements)
	}
}
