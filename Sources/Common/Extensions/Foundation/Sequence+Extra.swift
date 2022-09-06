import Foundation

public extension Sequence {
	func asyncForEach(
		_ operation: (Element) async throws -> Void
	) async rethrows {
		for element in self {
			try await operation(element)
		}
	}
}
