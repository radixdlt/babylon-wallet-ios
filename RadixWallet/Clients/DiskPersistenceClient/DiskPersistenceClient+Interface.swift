// MARK: - DiskPersistenceClient
struct DiskPersistenceClient {
	var save: Save
	var load: Load
	var remove: Remove
	var removeAll: RemoveAll
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
