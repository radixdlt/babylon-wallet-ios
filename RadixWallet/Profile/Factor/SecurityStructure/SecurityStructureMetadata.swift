import EngineToolkit

// MARK: - SecurityStructureMetadata
public struct SecurityStructureMetadata: Sendable, Hashable, Codable, Identifiable {
	public typealias ID = UUID
	public let id: ID

	/// can be renamed
	public var label: String

	public let createdOn: Date

	// should update date when any changes occur
	public var lastUpdatedOn: Date

	public init(
		id: ID? = nil,
		label: String = "",
		createdOn: Date? = nil,
		lastUpdatedOn: Date? = nil
	) {
		@Dependency(\.date) var date
		@Dependency(\.uuid) var uuid
		self.id = id ?? uuid()
		self.label = label
		self.createdOn = createdOn ?? date()
		self.lastUpdatedOn = lastUpdatedOn ?? date()
	}
}
