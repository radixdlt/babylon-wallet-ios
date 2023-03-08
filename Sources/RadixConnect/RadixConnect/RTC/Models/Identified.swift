// MARK: - Identified
/// Attaches a given ID to a given type
public struct Identified<Content, ID: Hashable>: Identifiable {
	public let content: Content
	public let id: ID

	init(content: Content, id: ID) {
		self.content = content
		self.id = id
	}
}

// MARK: Equatable
extension Identified: Equatable where Content: Equatable, ID: Equatable {}

// MARK: Sendable
extension Identified: Sendable where Content: Sendable, ID: Sendable {}
