// MARK: - Identified
/// Attaches a given ID to a given type
public struct Identified<T, ID> {
	public let content: T
	public let id: ID

	init(content: T, id: ID) {
		self.content = content
		self.id = id
	}
}

// MARK: Equatable
extension Identified: Equatable where T: Equatable, ID: Equatable {}

// MARK: Sendable
extension Identified: Sendable where T: Sendable, ID: Sendable {}
