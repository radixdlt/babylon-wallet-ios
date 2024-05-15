import CloudKit
import ComposableArchitecture
import DependenciesAdditions
import os

extension CKRecord.RecordType {
	static let profile = "Profile"
}

extension CKRecord.FieldKey {
	static let content = "Content"
}

extension CloudBackupClient {
	struct MissingCloudKitIdentifierError: Error {}
	struct IncorrectRecordTypeError: Error {}
	struct NoProfileInRecordError: Error {}
	struct ProfileMissingFromKeychainError: Error { let id: ProfileID }

	public static let liveValue: Self = .live()

	private static let cloudBackupIdentifierKey = "cloud-backup-identifier"

	public static func live(
		profileStore: ProfileStore = .shared
	) -> CloudBackupClient {
		@Dependency(\.secureStorageClient) var secureStorageClient
		@Dependency(\.userDefaults) var userDefaults

		let cloudContainer = ProcessInfo.processInfo.environment[Self.cloudBackupIdentifierKey].map(CKContainer.init)

		@Sendable
		func container() throws -> CKContainer {
			guard let cloudContainer else { throw MissingCloudKitIdentifierError() }
			return cloudContainer
		}

		@Sendable
		func fetchProfileRecord(_ id: CKRecord.ID) async throws -> CKRecord {
			try await container().privateCloudDatabase.record(for: id)
		}

		@Sendable
		func fetchAllProfileRecords() async throws -> [CKRecord] {
			let records = try await container().privateCloudDatabase.records(
				matching: .init(recordType: .profile, predicate: .init(value: true))
			)
			return try records.matchResults.map { try $0.1.get() }
		}

		@Sendable
		func extractProfile(_ record: CKRecord) throws -> Profile {
			guard record.recordType == .profile else {
				throw IncorrectRecordTypeError()
			}
			guard let asset = record[.content] as? CKAsset, let fileURL = asset.fileURL else {
				throw NoProfileInRecordError()
			}

			let data = try Data(contentsOf: fileURL)
			let profile = try Profile(jsonData: data)
			try FileManager.default.removeItem(at: fileURL)

			return profile
		}

		@discardableResult
		@Sendable
		func uploadProfileToICloud(_ profile: Profile, existingRecord: CKRecord?) async throws -> CKRecord {
			let fileManager = FileManager.default
			let tempDirectoryURL = fileManager.temporaryDirectory
			let fileURL = tempDirectoryURL.appendingPathComponent(UUID().uuidString)
			try profile.jsonData().write(to: fileURL)

			let record = existingRecord ?? .init(recordType: .profile, recordID: .init(recordName: profile.id.uuidString))
			record[.content] = CKAsset(fileURL: fileURL)

			let savedRecord = try await container().privateCloudDatabase.save(record)
			try fileManager.removeItem(at: fileURL)

			return savedRecord
		}

		@Sendable
		func backupProfileAndSaveResult(_ profile: Profile) async {
			let existingRecord = try? await fetchProfileRecord(.init(recordName: profile.id.uuidString))
			let result: BackupResult.Result
			do {
				try await uploadProfileToICloud(profile, existingRecord: existingRecord)
				result = .success
			} catch CKError.accountTemporarilyUnavailable {
				result = .temporarilyUnavailable
			} catch CKError.notAuthenticated {
				result = .notAuthenticated
			} catch {
				result = .failure
			}

			try? userDefaults.setLastCloudBackup(result, of: profile)
		}

		return .init(
			startAutomaticBackups: {
				let timer = AsyncTimerSequence(every: .seconds(60))
				let profiles = await profileStore.values()

				for try await (profile, _) in combineLatest(profiles, timer) {
					guard !Task.isCancelled else { print("•• cancel auto backups"); return }
					print("•• tick or profile change")
					guard profile.appPreferences.security.isCloudProfileSyncEnabled else {
						print("•• CloudProfileSync disabled")
						continue
					}

					let last = userDefaults.getLastCloudBackups[profile.id]
					if let last, last.result == .success, last.profileHash == profile.hashValue {
						print("•• alredy up to date")
						continue
					}

					print("•• will backup")
					await backupProfileAndSaveResult(profile)
				}
			},
			loadDeviceID: {
				try? secureStorageClient.loadDeviceInfo()?.id
			},
			migrateProfilesFromKeychain: {
				let activeProfile = await profileStore.profile.id
				let backedUpRecords = try await fetchAllProfileRecords()
				guard let headerList = try secureStorageClient.loadProfileHeaderList() else { return [] }

				return try await headerList.ids.asyncCompactMap { id in
					guard id != activeProfile else {
						// No need to migrate the currently active profile
						return nil
					}

					guard let profile = try secureStorageClient.loadProfile(id) else {
						throw ProfileMissingFromKeychainError(id: id)
					}

					guard !profile.networks.isEmpty, profile.appPreferences.security.isCloudProfileSyncEnabled else {
						return nil
					}
					let backedUpRecord = backedUpRecords.first { $0.recordID.recordName == id.uuidString }

					if let backedUpRecord, try extractProfile(backedUpRecord).header.lastModified >= profile.header.lastModified {
						return nil
					}

					let savedRecord = try await uploadProfileToICloud(profile, existingRecord: backedUpRecord)
					// Migration completed, deleting old copy
					try secureStorageClient.deleteProfile(profile.id)

					return savedRecord
				}
			},
			deleteProfileBackup: { id in
				try await container().privateCloudDatabase.deleteRecord(withID: .init(recordName: id.uuidString))
				try userDefaults.removeLastCloudBackup(for: id)
			},
			checkAccountStatus: {
				try await container().accountStatus()
			},
			lastBackup: { id in
				userDefaults.lastCloudBackupValues(for: id)
			},
			loadProfile: { id in
				try await extractProfile(fetchProfileRecord(.init(recordName: id.uuidString)))
			},
			loadAllProfiles: {
				try await fetchAllProfileRecords().map(extractProfile)
			},
			backupProfile: {
				let profile = await profileStore.profile
				let existingRecord = try? await fetchProfileRecord(.init(recordName: profile.id.uuidString))
				return try await uploadProfileToICloud(profile, existingRecord: existingRecord)
			}
		)
	}
}
