// MARK: - EqVoid
/// Useful when writing features where actions semantically have associated value
/// `TaskResult<Void>` which does not compile since `Void` is not `Equatable`. We
/// can now use `TaskResult<Unit>`.
public struct EqVoid: Sendable, Hashable, Codable, Error {
	public static var instance: Self { self.init() }

	private init() {}
}

// MARK: Identifiable
extension EqVoid: Identifiable {
	public var id: Self {
		self
	}
}
