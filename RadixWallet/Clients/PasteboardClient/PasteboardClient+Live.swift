typealias Pasteboard = UIPasteboard

// MARK: - PasteboardClient + DependencyKey
extension PasteboardClient: DependencyKey {
	typealias Value = PasteboardClient
	static let liveValue = Self.live()

	static func live(pasteboard: Pasteboard = .general) -> Self {
		let copyEvents = AsyncPassthroughSubject<String>()

		return Self(
			copyEvents: { copyEvents.share().eraseToAnyAsyncSequence() },
			copyString: { aString in
				pasteboard.string = aString
				copyEvents.send(aString)
			},
			getString: {
				pasteboard.string
			}
		)
	}
}

// MARK: - Pasteboard + @unchecked Sendable
extension Pasteboard: @unchecked Sendable {}
