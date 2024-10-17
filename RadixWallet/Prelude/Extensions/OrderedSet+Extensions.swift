
extension OrderedSet {
	/// Validates that `elements` collection contains unique elements.
	init(validating elements: some Collection<Element>) throws {
		self.init(elements)
		guard self.count == elements.count else {
			throw UnexpectedDuplicatesFound()
		}
	}

	struct UnexpectedDuplicatesFound: Swift.Error {}
}
