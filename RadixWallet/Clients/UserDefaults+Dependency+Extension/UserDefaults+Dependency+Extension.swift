
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
	case lastCloudBackups
	case lastManualBackups

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

	public var getLastCloudBackups: [UUID: BackupMetadata] {
		getLastBackups(cloud: true)
	}

	public func setLastCloudBackup(_ status: BackupMetadata.Status, of profile: Profile) throws {
		try setLastBackup(cloud: true, status: status, of: profile)
	}

	public func lastCloudBackupValues(for profileID: ProfileID) -> AnyAsyncSequence<BackupMetadata> {
		lastBackupValues(cloud: true, for: profileID)
	}

	public var getLastManualBackups: [UUID: BackupMetadata] {
		getLastBackups(cloud: false)
	}

	public func setLastManualBackup(_ status: BackupMetadata.Status, of profile: Profile) throws {
		try setLastBackup(cloud: false, status: status, of: profile)
	}

	public func lastManualBackupValues(for profileID: ProfileID) -> AnyAsyncSequence<BackupMetadata> {
		lastBackupValues(cloud: false, for: profileID)
	}
}

// MARK: - BackupMetadata
public struct BackupMetadata: Codable, Sendable {
	public let date: Date
	public let profileHash: Int
	public let status: Status

	public enum Status: Codable, Sendable {
		case success
		case notAuthorized
		case failure
	}
}

extension UserDefaults.Dependency {
	private func setLastBackup(cloud: Bool, status: BackupMetadata.Status, of profile: Profile) throws {
		let key = backupKey(cloud: cloud)
		var backups: [UUID: BackupMetadata] = getLastBackups(cloud: cloud)
		backups[profile.id] = .init(
			date: profile.header.lastModified,
			profileHash: profile.hashValue,
			status: status
		)

		@Dependency(\.jsonEncoder) var jsonEncoder
		let data = try jsonEncoder().encode(backups)
		set(data: data, key: key)
	}

	private func getLastBackups(cloud: Bool) -> [UUID: BackupMetadata] {
		@Dependency(\.jsonDecoder) var jsonDecoder
		guard let data = data(key: backupKey(cloud: cloud)) else { return [:] }
		guard let result = try? jsonDecoder().decode([UUID: BackupMetadata].self, from: data) else { return [:] }
		return result
	}

	private func lastBackupValues(cloud: Bool, for profileID: ProfileID) -> AnyAsyncSequence<BackupMetadata> {
		@Dependency(\.jsonDecoder) var jsonDecoder
		return dataValues(forKey: backupKey(cloud: cloud).rawValue).compactMap { data -> BackupMetadata? in
			guard let data else { return nil }
			guard let backups = try? jsonDecoder().decode([UUID: BackupMetadata].self, from: data) else { return nil }
			return backups[profileID]
		}
		.eraseToAnyAsyncSequence()
	}

	private func backupKey(cloud: Bool) -> UserDefaultsKey {
		cloud ? .lastCloudBackups : .lastManualBackups
	}
}
