// MARK: - PasteboardClient + TestDependencyKey
extension PasteboardClient: TestDependencyKey {
	static let previewValue = Self.noop

	static let testValue = Self(
		copyEvents: unimplemented("\(Self.self).copyEvents", placeholder: noop.copyEvents),
		copyString: unimplemented("\(Self.self).copyString"),
		getString: unimplemented("\(Self.self).getString", placeholder: noop.getString)
	)

	static let noop = Self(
		copyEvents: { AsyncPassthroughSubject<String>().eraseToAnyAsyncSequence() },
		copyString: { _ in },
		getString: { nil }
	)
}

extension DependencyValues {
	var pasteboardClient: PasteboardClient {
		get { self[PasteboardClient.self] }
		set { self[PasteboardClient.self] = newValue }
	}
}
