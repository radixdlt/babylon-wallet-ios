// MARK: - EqVoid
/// Useful when writing features where actions semantically have associated value
/// `TaskResult<Void>` which does not compile since `Void` is not `Equatable`. We
/// can now use `TaskResult<Unit>`.
struct EqVoid: Sendable, Hashable, Codable, Error {
	static var instance: Self { self.init() }

	private init() {}
}

// MARK: Identifiable
extension EqVoid: Identifiable {
	var id: Self {
		self
	}
}
