// MARK: - PasteboardClient

public struct PasteboardClient: Sendable {
	public var copyEvents: CopyEvents
	public var copyString: CopyString
	public var getString: GetString
}

extension PasteboardClient {
	public typealias CopyEvents = @Sendable () -> AnyAsyncSequence<String>
	public typealias CopyString = @Sendable (String) -> Void
	public typealias GetString = @Sendable () -> String?
}
