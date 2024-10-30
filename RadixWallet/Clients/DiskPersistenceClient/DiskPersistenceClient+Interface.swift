// MARK: - DiskPersistenceClient
struct DiskPersistenceClient: Sendable {
	var save: Save
	var load: Load
	var remove: Remove
	var removeAll: RemoveAll

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
	typealias Save = @Sendable (Encodable, String) throws -> Void
	typealias Load = @Sendable (Decodable.Type, String) throws -> Decodable
	typealias Remove = @Sendable (String) throws -> Void
	typealias RemoveAll = @Sendable () throws -> Void
}

extension DependencyValues {
	var diskPersistenceClient: DiskPersistenceClient {
		get { self[DiskPersistenceClient.self] }
		set { self[DiskPersistenceClient.self] = newValue }
	}
}
