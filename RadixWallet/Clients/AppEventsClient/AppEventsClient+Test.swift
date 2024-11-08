// MARK: - AppEventsClient + TestDependencyKey
extension AppEventsClient: TestDependencyKey {
	static let previewValue = Self.noop

	static let testValue = Self(
		handleEvent: unimplemented("\(Self.self).handleEvent"),
		events: unimplemented("\(Self.self).events")
	)
}

extension AppEventsClient {
	static let noop = Self(
		handleEvent: { _ in },
		events: { AsyncLazySequence([]).eraseToAnyAsyncSequence() }
	)
}
