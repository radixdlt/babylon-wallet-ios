// MARK: - AppEventsClient + TestDependencyKey
extension AppEventsClient: TestDependencyKey {
	public static let previewValue = Self.noop

	public static let testValue = Self(
		handleEvent: unimplemented("\(Self.self).handleEvent"),
		events: unimplemented("\(Self.self).events")
	)
}

extension AppEventsClient {
	public static let noop = Self(
		handleEvent: { _ in },
		events: { AsyncLazySequence([]).eraseToAnyAsyncSequence() }
	)
}
