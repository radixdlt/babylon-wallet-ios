import Dependencies

// MARK: - UserDefaultsClient
public struct UserDefaultsClient: Sendable {
	public typealias Key = String

	public var stringForKey: @Sendable (Key) -> String?
	public var boolForKey: @Sendable (Key) -> Bool
	public var dataForKey: @Sendable (Key) -> Data?
	public var doubleForKey: @Sendable (Key) -> Double
	public var integerForKey: @Sendable (Key) -> Int
	public var remove: @Sendable (Key) async -> Void
	public var setString: @Sendable (String, Key) async -> Void
	public var setBool: @Sendable (Bool, Key) async -> Void
	public var setData: @Sendable (Data?, Key) async -> Void
	public var setDouble: @Sendable (Double, Key) async -> Void
	public var setInteger: @Sendable (Int, Key) async -> Void
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
	private static let hideMigrateOlympiaButtonKey = "hideMigrateOlympiaButton"
	public var hideMigrateOlympiaButton: Bool {
		boolForKey(Self.hideMigrateOlympiaButtonKey)
	}

	public func setHideMigrateOlympiaButton(_ value: Bool) async {
		await setBool(value, Self.hideMigrateOlympiaButtonKey)
	}
}
