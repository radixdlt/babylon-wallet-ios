// MARK: - AppEventsClient + TestDependencyKey
extension AppEventsClient: TestDependencyKey {
	public static let previewValue = Self.noop

	public static let testValue = Self(
		handleEvent: unimplemented("\(Self.self).handleEvent")
	)
}

extension AppEventsClient {
	public static let noop = Self(
		handleEvent: { _ in }
	)
}
