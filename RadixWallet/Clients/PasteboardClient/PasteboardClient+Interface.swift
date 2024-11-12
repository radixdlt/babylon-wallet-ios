// MARK: - PasteboardClient
struct PasteboardClient: Sendable {
	var copyEvents: CopyEvents
	var copyString: CopyString
	var getString: GetString
}

extension PasteboardClient {
	typealias CopyEvents = @Sendable () -> AnyAsyncSequence<String>
	typealias CopyString = @Sendable (String) -> Void
	typealias GetString = @Sendable () -> String?
}
