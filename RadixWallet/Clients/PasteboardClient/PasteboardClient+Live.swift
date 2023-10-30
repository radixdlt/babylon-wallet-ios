public typealias Pasteboard = UIPasteboard

// MARK: - PasteboardClient + DependencyKey
extension PasteboardClient: DependencyKey {
	public typealias Value = PasteboardClient
	public static let liveValue = Self.live()

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

// MARK: - Pasteboard + Sendable
extension Pasteboard: @unchecked Sendable {}
