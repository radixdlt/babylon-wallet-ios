// MARK: - UserDefaultsClient
public struct UserDefaultsClient: Sendable {
	public enum Key: String, Sendable, Hashable, CaseIterable {
		case hideMigrateOlympiaButton
		case epochForWhenLastUsedByAccountAddress

		/// DO NOT CHANGE THIS KEY
		case activeProfileID

		case mnemonicsUserClaimsToHaveBackedUp
	}

	public var stringForKey: @Sendable (Key) -> String?
	public var boolForKey: @Sendable (Key) -> Bool
	public var dataForKey: @Sendable (Key) -> Data?
	public var doubleForKey: @Sendable (Key) -> Double
	public var integerForKey: @Sendable (Key) -> Int
	public typealias RemoveValueForKey = @Sendable (Key) -> Void
	public var remove: RemoveValueForKey
	public var setString: @Sendable (String, Key) -> Void
	public var setBool: @Sendable (Bool, Key) -> Void
	public var setData: @Sendable (Data?, Key) -> Void
	public var setDouble: @Sendable (Double, Key) -> Void
	public var setInteger: @Sendable (Int, Key) -> Void
	public var removeAll: @Sendable (Set<Key>) -> Void
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

	public func save(codable model: some Codable, forKey key: Key) throws {
		@Dependency(\.jsonEncoder) var jsonEncoder
		let data = try jsonEncoder().encode(model)
		self.setData(data, key)
	}
}

extension UserDefaultsClient {
	public func removeAll(but exceptions: Set<Key> = []) {
		removeAll(exceptions)
	}
}

extension UserDefaultsClient {
	public var hideMigrateOlympiaButton: Bool {
		boolForKey(.hideMigrateOlympiaButton)
	}

	public func setHideMigrateOlympiaButton(_ value: Bool) {
		setBool(value, .hideMigrateOlympiaButton)
	}
}

extension UserDefaultsClient {
	public func getActiveProfileID() -> ProfileSnapshot.Header.ID? {
		stringForKey(.activeProfileID).flatMap(UUID.init(uuidString:))
	}

	public func setActiveProfileID(_ id: ProfileSnapshot.Header.UsedDeviceInfo.ID) {
		setString(id.uuidString, .activeProfileID)
	}

	public func removeActiveProfileID() {
		remove(.activeProfileID)
	}
}
