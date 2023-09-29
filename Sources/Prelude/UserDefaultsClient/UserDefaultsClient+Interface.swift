import Dependencies

// MARK: - UserDefaultsClient
public struct UserDefaultsClient: Sendable {
	public enum Key: String, Sendable, Hashable, CaseIterable {
		case hideMigrateOlympiaButton
		case epochForWhenLastUsedByAccountAddress

		/// DO NOT CHANGE THIS KEY
		case activeProfileID

		case accountsThatNeedRecovery
		case mnemonicsUserClaimsToHaveBackedUp
	}

	public var stringForKey: @Sendable (Key) -> String?
	public var boolForKey: @Sendable (Key) -> Bool
	public var dataForKey: @Sendable (Key) -> Data?
	public var doubleForKey: @Sendable (Key) -> Double
	public var integerForKey: @Sendable (Key) -> Int
	public typealias RemoveValueForKey = @Sendable (Key) async -> Void
	public var remove: RemoveValueForKey
	public var setString: @Sendable (String, Key) async -> Void
	public var setBool: @Sendable (Bool, Key) async -> Void
	public var setData: @Sendable (Data?, Key) async -> Void
	public var setDouble: @Sendable (Double, Key) async -> Void
	public var setInteger: @Sendable (Int, Key) async -> Void
	public var removeAll: @Sendable (Set<Key>) async -> Void
}

extension UserDefaultsClient {
	public func loadCodable<Model: Codable>(
		key: Key, type: Model.Type = Model.self
	) throws -> Model? {
		@Dependency(\.jsonDecoder) var jsonDecoder
		guard let data = self.dataForKey(key) else {
			return nil
		}
		return try jsonDecoder().decode(Model.self, from: data)
	}

	public func save<Model: Codable>(codable model: Model, forKey key: Key) async throws {
		@Dependency(\.jsonEncoder) var jsonEncoder
		let data = try jsonEncoder().encode(model)
		await self.setData(data, key)
	}
}

extension UserDefaultsClient {
	public func removeAll(but exceptions: Set<Key> = []) async {
		await removeAll(exceptions)
	}
}

extension UserDefaultsClient {
	public var hideMigrateOlympiaButton: Bool {
		boolForKey(.hideMigrateOlympiaButton)
	}

	public func setHideMigrateOlympiaButton(_ value: Bool) async {
		await setBool(value, .hideMigrateOlympiaButton)
	}
}
