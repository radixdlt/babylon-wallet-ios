import Foundation

// MARK: - PasteboardClient
public struct PasteboardClient {
	public var copyString: @Sendable (String) -> Void
	public var getString: @Sendable () -> String?
}
