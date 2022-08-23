import Foundation

#if DEBUG
public extension PasteboardClient {
	static let noop = Self(
		copyString: { _ in },
		getString: { nil }
	)
}
#endif
