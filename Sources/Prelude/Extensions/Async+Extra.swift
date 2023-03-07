public extension AsyncSequence {
	/// Waits and returns the first element from the seqeunce
	func first() async throws -> Element {
		for try await element in self.prefix(1) {
			return element
		}
		throw CancellationError()
	}
}
