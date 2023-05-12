import ClientPrelude

// MARK: - DiskPersistenceClient
public struct DiskPersistenceClient: Sendable {
	public var save: Save
	public var load: Load
	public var remove: Remove
	public var removeAll: RemoveAll

	init(
		save: @escaping Save,
		load: @escaping Load,
		remove: @escaping Remove,
		removeAll: @escaping RemoveAll
	) {
		self.save = save
		self.load = load
		self.remove = remove
		self.removeAll = removeAll
	}
}

extension DiskPersistenceClient {
	public typealias Save = @Sendable (Codable, String) async throws -> Void
	public typealias Load = @Sendable (Codable.Type, String) async throws -> Codable?
	public typealias Remove = @Sendable (String) async throws -> Void
	public typealias RemoveAll = @Sendable () async throws -> Void
}

public extension DependencyValues {
	var diskPersistenceClient: DiskPersistenceClient {
		get { self[DiskPersistenceClient.self] }
		set { self[DiskPersistenceClient.self] = newValue }
	}
}
