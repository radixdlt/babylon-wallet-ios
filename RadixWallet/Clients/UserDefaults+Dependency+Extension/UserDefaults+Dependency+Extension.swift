
import DependenciesAdditions
import Sargon

// MARK: - UserDefaultsKey
public enum UserDefaultsKey: String, Sendable, Hashable, CaseIterable {
	case hideMigrateOlympiaButton
	case showRadixBanner
	case epochForWhenLastUsedByAccountAddress
	case transactionsCompletedCounter
	case dateOfLastSubmittedNPSSurvey
	case npsSurveyUserID
	case didMigrateKeychainProfiles

	/// DO NOT CHANGE THIS KEY
	case activeProfileID

	case mnemonicsUserClaimsToHaveBackedUp
}

extension UserDefaults.Dependency {
	public typealias Key = UserDefaultsKey
	public static let radix: Self = .init(.init(
		suiteName: "group.com.radixpublishing.preview"
	)!)
}

extension UserDefaults.Dependency {
	public func codableValues<T: Sendable & Codable>(key: Key, codable: T.Type = T.self) -> AnyAsyncSequence<Result<T?, Error>> {
		@Dependency(\.jsonDecoder) var jsonDecoder
		return self.dataValues(forKey: key.rawValue).map {
			if let data = $0 {
				Result { try jsonDecoder().decode(T.self, from: data) }
			} else {
				Result.success(nil)
			}
		}
		.eraseToAnyAsyncSequence()
	}

	public func bool(key: Key, default defaultTo: Bool = false) -> Bool {
		bool(forKey: key.rawValue) ?? defaultTo
	}

	public func data(key: Key) -> Data? {
		data(forKey: key.rawValue)
	}

	public func string(key: Key) -> String? {
		string(forKey: key.rawValue)
	}

	public func set(data: Data, key: Key) {
		set(data, forKey: key.rawValue)
	}

	public func set(string: String?, key: Key) {
		set(string, forKey: key.rawValue)
	}

	public func loadCodable<Model: Codable>(
		key: Key, type: Model.Type = Model.self
	) throws -> Model? {
		@Dependency(\.jsonDecoder) var jsonDecoder
		guard let data = self.data(key: key) else {
			return nil
		}
		return try jsonDecoder().decode(Model.self, from: data)
	}

	public func save(codable model: some Codable, forKey key: Key) throws {
		@Dependency(\.jsonEncoder) var jsonEncoder
		let data = try jsonEncoder().encode(model)
		self.set(data: data, key: key)
	}

	public func removeAll(but exceptions: Set<Key> = []) {
		for key in Set(Key.allCases).subtracting(exceptions) {
			remove(key)
		}
	}

	public func remove(_ key: Key) {
		self.removeValue(forKey: key.rawValue)
	}

	public var hideMigrateOlympiaButton: Bool {
		bool(key: .hideMigrateOlympiaButton)
	}

	public func setHideMigrateOlympiaButton(_ value: Bool) {
		set(value, forKey: Key.hideMigrateOlympiaButton.rawValue)
	}

	public var showRadixBanner: Bool {
		bool(key: .showRadixBanner)
	}

	public func setShowRadixBanner(_ value: Bool) {
		set(value, forKey: Key.showRadixBanner.rawValue)
	}

	public func getActiveProfileID() -> ProfileID? {
		string(forKey: Key.activeProfileID.rawValue).flatMap(UUID.init(uuidString:))
	}

	public func setActiveProfileID(_ id: ProfileID) {
		set(id.uuidString, forKey: Key.activeProfileID.rawValue)
	}

	public func removeActiveProfileID() {
		remove(.activeProfileID)
	}

	public func getTransactionsCompletedCounter() -> Int? {
		integer(forKey: Key.transactionsCompletedCounter.rawValue)
	}

	public func setTransactionsCompletedCounter(_ count: Int) {
		set(count, forKey: Key.transactionsCompletedCounter.rawValue)
	}

	public func transactionsCompletedCounterValues() -> AsyncStream<Int?> {
		integerValues(forKey: Key.transactionsCompletedCounter.rawValue)
	}

	public func getDateOfLastSubmittedNPSSurvey() -> Date? {
		date(forKey: Key.dateOfLastSubmittedNPSSurvey.rawValue)
	}

	public func setDateOfLastSubmittedNPSSurvey(_ date: Date) {
		set(date, forKey: Key.dateOfLastSubmittedNPSSurvey.rawValue)
	}

	public func getNPSSurveyUserId() -> UUID? {
		string(forKey: Key.npsSurveyUserID.rawValue).flatMap(UUID.init(uuidString:))
	}

	public func setNPSSurveyUserId(_ id: UUID) {
		set(id.uuidString, forKey: Key.npsSurveyUserID.rawValue)
	}

	public var getDidMigrateKeychainProfiles: Bool {
		bool(key: .didMigrateKeychainProfiles)
	}

	public func setDidMigrateKeychainProfiles(_ value: Bool) {
		set(value, forKey: Key.didMigrateKeychainProfiles.rawValue)
	}
}
