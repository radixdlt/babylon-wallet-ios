import Dependencies

// MARK: - PasteboardClient
public struct PasteboardClient: Sendable {
	public var copyString: @Sendable (String) -> Void
	public var getString: @Sendable () -> String?
}
