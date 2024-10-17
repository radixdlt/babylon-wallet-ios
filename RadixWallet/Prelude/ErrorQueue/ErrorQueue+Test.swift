
extension DependencyValues {
	var errorQueue: ErrorQueue {
		get { self[ErrorQueue.self] }
		set { self[ErrorQueue.self] = newValue }
	}
}

// MARK: - ErrorQueue + TestDependencyKey
extension ErrorQueue: TestDependencyKey {
	static let previewValue = liveValue

	static let testValue = Self(
		errors: unimplemented("\(Self.self).errors"),
		schedule: unimplemented("\(Self.self).schedule")
	)
}
