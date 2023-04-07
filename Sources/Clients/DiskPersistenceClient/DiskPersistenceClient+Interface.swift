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
	public typealias Save = @Sendable (Encodable, String) throws -> Void
	public typealias Load = @Sendable (Decodable.Type, String) throws -> Decodable
	public typealias Remove = @Sendable (String) throws -> Void
	public typealias RemoveAll = @Sendable () throws -> Void
}

public extension DependencyValues {
	var diskPersistenceClient: DiskPersistenceClient {
		get { self[DiskPersistenceClient.self] }
		set { self[DiskPersistenceClient.self] = newValue }
	}
}
