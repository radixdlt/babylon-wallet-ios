// MARK: - PasteboardClient + TestDependencyKey
extension PasteboardClient: TestDependencyKey {
	static let previewValue = Self(
		copyEvents: { AsyncPassthroughSubject<String>().eraseToAnyAsyncSequence() },
		copyString: { _ in },
		getString: { nil }
	)

	static let testValue = Self(
		copyEvents: unimplemented("\(Self.self).copyEvents"),
		copyString: unimplemented("\(Self.self).copyString"),
		getString: unimplemented("\(Self.self).getString")
	)
}

extension DependencyValues {
	var pasteboardClient: PasteboardClient {
		get { self[PasteboardClient.self] }
		set { self[PasteboardClient.self] = newValue }
	}
}
