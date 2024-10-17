
import DependenciesAdditions
import Sargon

// MARK: - UserDefaultsKey
enum UserDefaultsKey: String, Sendable, Hashable, CaseIterable {
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
	case appLockMessageShown

	/// DO NOT CHANGE THIS KEY
	case activeProfileID

	case mnemonicsUserClaimsToHaveBackedUp
}

extension UserDefaults.Dependency {
	typealias Key = UserDefaultsKey
	static let radix: Self = .init(.init(
		suiteName: "group.com.radixpublishing.preview"
	)!)
}

extension UserDefaults.Dependency {
	func codableValues<T: Sendable & Codable>(key: Key, codable: T.Type = T.self) -> AnyAsyncSequence<Result<T?, Error>> {
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

	func bool(key: Key, default defaultTo: Bool = false) -> Bool {
		bool(forKey: key.rawValue) ?? defaultTo
	}

	func data(key: Key) -> Data? {
		data(forKey: key.rawValue)
	}

	func string(key: Key) -> String? {
		string(forKey: key.rawValue)
	}

	func set(data: Data, key: Key) {
		set(data, forKey: key.rawValue)
	}

	func set(string: String?, key: Key) {
		set(string, forKey: key.rawValue)
	}

	func loadCodable<Model: Codable>(
		key: Key, type: Model.Type = Model.self
	) throws -> Model? {
		@Dependency(\.jsonDecoder) var jsonDecoder
		guard let data = self.data(key: key) else {
			return nil
		}
		return try jsonDecoder().decode(Model.self, from: data)
	}

	func save(codable model: some Codable, forKey key: Key) throws {
		@Dependency(\.jsonEncoder) var jsonEncoder
		let data = try jsonEncoder().encode(model)
		self.set(data: data, key: key)
	}

	func removeAll(but exceptions: Set<Key> = []) {
		for key in Set(Key.allCases).subtracting(exceptions) {
			remove(key)
		}
	}

	func remove(_ key: Key) {
		self.removeValue(forKey: key.rawValue)
	}

	var hideMigrateOlympiaButton: Bool {
		bool(key: .hideMigrateOlympiaButton)
	}

	func setHideMigrateOlympiaButton(_ value: Bool) {
		set(value, forKey: Key.hideMigrateOlympiaButton.rawValue)
	}

	func getActiveProfileID() -> ProfileID? {
		string(forKey: Key.activeProfileID.rawValue).flatMap(UUID.init(uuidString:))
	}

	func setActiveProfileID(_ id: ProfileID) {
		set(id.uuidString, forKey: Key.activeProfileID.rawValue)
	}

	func removeActiveProfileID() {
		remove(.activeProfileID)
	}

	func getTransactionsCompletedCounter() -> Int? {
		integer(forKey: Key.transactionsCompletedCounter.rawValue)
	}

	func setTransactionsCompletedCounter(_ count: Int) {
		set(count, forKey: Key.transactionsCompletedCounter.rawValue)
	}

	func transactionsCompletedCounterValues() -> AsyncStream<Int?> {
		integerValues(forKey: Key.transactionsCompletedCounter.rawValue)
	}

	func getDateOfLastSubmittedNPSSurvey() -> Date? {
		date(forKey: Key.dateOfLastSubmittedNPSSurvey.rawValue)
	}

	func setDateOfLastSubmittedNPSSurvey(_ date: Date) {
		set(date, forKey: Key.dateOfLastSubmittedNPSSurvey.rawValue)
	}

	func getNPSSurveyUserId() -> UUID? {
		string(forKey: Key.npsSurveyUserID.rawValue).flatMap(UUID.init(uuidString:))
	}

	func setNPSSurveyUserId(_ id: UUID) {
		set(id.uuidString, forKey: Key.npsSurveyUserID.rawValue)
	}

	var getMigratedKeychainProfiles: Set<ProfileID> {
		(try? loadCodable(key: .migratedKeychainProfiles)) ?? []
	}

	func appendMigratedKeychainProfiles(_ value: some Collection<ProfileID>) throws {
		var migrated = getMigratedKeychainProfiles
		migrated.append(contentsOf: value)
		try save(codable: migrated, forKey: .migratedKeychainProfiles)
	}

	var getLastCloudBackups: [ProfileID: BackupResult] {
		(try? loadCodable(key: .lastCloudBackups)) ?? [:]
	}

	func removeLastCloudBackup(for id: ProfileID) throws {
		var backups: [UUID: BackupResult] = getLastCloudBackups
		backups[id] = nil
		try save(codable: backups, forKey: .lastCloudBackups)
	}

	func setLastCloudBackup(_ result: BackupResult.Result, of header: Profile.Header, at date: Date = .now) throws {
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

	func lastCloudBackupValues(for profileID: ProfileID) -> AnyAsyncSequence<BackupResult?> {
		lastBackupValues(for: profileID, key: .lastCloudBackups)
	}

	var getLastManualBackups: [ProfileID: BackupResult] {
		(try? loadCodable(key: .lastManualBackups)) ?? [:]
	}

	/// Only call this on successful manual backups
	func setLastManualBackup(of profile: Profile) throws {
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

	func lastManualBackupValues(for profileID: ProfileID) -> AnyAsyncSequence<BackupResult?> {
		lastBackupValues(for: profileID, key: .lastManualBackups)
	}

	private func lastBackupValues(for profileID: ProfileID, key: UserDefaultsKey) -> AnyAsyncSequence<BackupResult?> {
		codableValues(key: key, codable: [ProfileID: BackupResult].self)
			.map { (try? $0.get())?[profileID] }
			.eraseToAnyAsyncSequence()
	}

	func getLastSyncedAccountsWithCE() -> String? {
		string(forKey: Key.lastSyncedAccountsWithCE.rawValue)
	}

	func setLastSyncedAccountsWithCE(_ value: String) {
		set(value, forKey: Key.lastSyncedAccountsWithCE.rawValue)
	}

	var showRelinkConnectorsAfterUpdate: Bool {
		bool(key: .showRelinkConnectorsAfterUpdate)
	}

	func setShowRelinkConnectorsAfterUpdate(_ value: Bool) {
		set(value, forKey: Key.showRelinkConnectorsAfterUpdate.rawValue)
	}

	var showRelinkConnectorsAfterProfileRestore: Bool {
		bool(key: .showRelinkConnectorsAfterProfileRestore)
	}

	func setShowRelinkConnectorsAfterProfileRestore(_ value: Bool) {
		set(value, forKey: Key.showRelinkConnectorsAfterProfileRestore.rawValue)
	}

	func getHomeCards() -> Data? {
		data(key: .homeCards)
	}

	func setHomeCards(_ value: Data) {
		set(data: value, key: .homeCards)
	}

	var appLockMessageShown: Bool {
		bool(key: .appLockMessageShown)
	}

	func setAppLockMessageShown(_ value: Bool) {
		set(value, forKey: Key.appLockMessageShown.rawValue)
	}
}

// MARK: - BackupResult
struct BackupResult: Hashable, Codable, Sendable {
	private static let timeoutInterval: TimeInterval = 5 * 60

	let date: Date
	let saveIdentifier: String
	let result: Result
	let lastSuccess: Date?

	var succeeded: Bool {
		result == .success
	}

	var failed: Bool {
		switch result {
		case .failure:
			true
		case let .started(date):
			Date.now.timeIntervalSince(date) > Self.timeoutInterval
		case .success:
			false
		}
	}

	var isFinal: Bool {
		switch result {
		case .started: false
		case .failure, .success: true
		}
	}

	enum Result: Hashable, Codable, Sendable {
		case started(Date)
		case success
		case failure(Failure)

		enum Failure: Hashable, Codable, Sendable {
			case temporarilyUnavailable
			case notAuthenticated
			case other
		}
	}
}

extension Profile.Header {
	var saveIdentifier: String {
		"\(lastModified.timeIntervalSince1970)-\(lastUsedOnDevice.id.uuidString)"
	}
}
