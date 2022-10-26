import ComposableArchitecture
import Foundation

// MARK: - PasteboardClient
public struct PasteboardClient {
	public var copyString: @Sendable (String) -> Void
	public var getString: @Sendable () -> String?
}

public extension DependencyValues {
	var pasteboardClient: PasteboardClient {
		get { self[PasteboardClient.self] }
		set { self[PasteboardClient.self] = newValue }
	}
}
