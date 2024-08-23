
import DependenciesAdditions
import Sargon

// MARK: - UserDefaultsKey
public enum UserDefaultsKey: String, Sendable, Hashable, CaseIterable {
	case hideMigrateOlympiaButton
	case epochForWhenLastUsedByAccountAddress
	case transactionsCompletedCounter
	case dateOfLastSubmittedNPSSurvey
	case npsSurveyUserID
	case migratedKeychainProfiles
	case lastCloudBackups
	case lastManualBackups
	case lastSyncedAccountsWithCE
	case showRelinkConnectorsAfterUpdate
	case showRelinkConnectorsAfterProfileRestore
	case homeCards

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

	public var getMigratedKeychainProfiles: Set<ProfileID> {
		(try? loadCodable(key: .migratedKeychainProfiles)) ?? []
	}

	public func appendMigratedKeychainProfiles(_ value: some Collection<ProfileID>) throws {
		var migrated = getMigratedKeychainProfiles
		migrated.formUnion(value)
		try save(codable: migrated, forKey: .migratedKeychainProfiles)
	}

	public var getLastCloudBackups: [ProfileID: BackupResult] {
		(try? loadCodable(key: .lastCloudBackups)) ?? [:]
	}

	public func removeLastCloudBackup(for id: ProfileID) throws {
		var backups: [UUID: BackupResult] = getLastCloudBackups
		backups[id] = nil
		try save(codable: backups, forKey: .lastCloudBackups)
	}

	public func setLastCloudBackup(_ result: BackupResult.Result, of header: Profile.Header, at date: Date = .now) throws {
		var backups: [UUID: BackupResult] = getLastCloudBackups
		let lastSuccess = result == .success ? date : backups[header.id]?.lastSuccess
		backups[header.id] = .init(
			date: date,
			saveIdentifier: header.saveIdentifier,
			result: result,
			lastSuccess: lastSuccess
		)

		try save(codable: backups, forKey: .lastCloudBackups)
	}

	public func lastCloudBackupValues(for profileID: ProfileID) -> AnyAsyncSequence<BackupResult?> {
		lastBackupValues(for: profileID, key: .lastCloudBackups)
	}

	public var getLastManualBackups: [ProfileID: BackupResult] {
		(try? loadCodable(key: .lastManualBackups)) ?? [:]
	}

	/// Only call this on successful manual backups
	public func setLastManualBackup(of profile: Profile) throws {
		var backups: [ProfileID: BackupResult] = getLastManualBackups
		let now = Date.now
		backups[profile.id] = .init(
			date: now,
			saveIdentifier: profile.header.saveIdentifier,
			result: .success,
			lastSuccess: now
		)

		try save(codable: backups, forKey: .lastManualBackups)
	}

	public func lastManualBackupValues(for profileID: ProfileID) -> AnyAsyncSequence<BackupResult?> {
		lastBackupValues(for: profileID, key: .lastManualBackups)
	}

	private func lastBackupValues(for profileID: ProfileID, key: UserDefaultsKey) -> AnyAsyncSequence<BackupResult?> {
		codableValues(key: key, codable: [ProfileID: BackupResult].self)
			.map { (try? $0.get())?[profileID] }
			.eraseToAnyAsyncSequence()
	}

	public func getLastSyncedAccountsWithCE() -> String? {
		string(forKey: Key.lastSyncedAccountsWithCE.rawValue)
	}

	public func setLastSyncedAccountsWithCE(_ value: String) {
		set(value, forKey: Key.lastSyncedAccountsWithCE.rawValue)
	}

	public var showRelinkConnectorsAfterUpdate: Bool {
		bool(key: .showRelinkConnectorsAfterUpdate)
	}

	public func setShowRelinkConnectorsAfterUpdate(_ value: Bool) {
		set(value, forKey: Key.showRelinkConnectorsAfterUpdate.rawValue)
	}

	public var showRelinkConnectorsAfterProfileRestore: Bool {
		bool(key: .showRelinkConnectorsAfterProfileRestore)
	}

	public func setShowRelinkConnectorsAfterProfileRestore(_ value: Bool) {
		set(value, forKey: Key.showRelinkConnectorsAfterProfileRestore.rawValue)
	}

	public func getHomeCards() -> Data? {
		data(key: .homeCards)
	}

	public func setHomeCards(_ value: Data) {
		set(data: value, key: .homeCards)
	}
}

// MARK: - BackupResult
public struct BackupResult: Hashable, Codable, Sendable {
	private static let timeoutInterval: TimeInterval = 5 * 60

	public let date: Date
	public let saveIdentifier: String
	public let result: Result
	public let lastSuccess: Date?

	public var succeeded: Bool {
		result == .success
	}

	public var failed: Bool {
		switch result {
		case .failure:
			true
		case let .started(date):
			Date.now.timeIntervalSince(date) > Self.timeoutInterval
		case .success:
			false
		}
	}

	public var isFinal: Bool {
		switch result {
		case .started: false
		case .failure, .success: true
		}
	}

	public enum Result: Hashable, Codable, Sendable {
		case started(Date)
		case success
		case failure(Failure)

		public enum Failure: Hashable, Codable, Sendable {
			case temporarilyUnavailable
			case notAuthenticated
			case other
		}
	}
}

extension Profile.Header {
	public var saveIdentifier: String {
		"\(lastModified.timeIntervalSince1970)-\(lastUsedOnDevice.id.uuidString)"
	}
}
