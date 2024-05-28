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

	public static func live(
		profileStore: ProfileStore = .shared
	) -> CloudBackupClient {
		@Dependency(\.secureStorageClient) var secureStorageClient
		@Dependency(\.userDefaults) var userDefaults

		let cloudContainer: CKContainer = .default()

		@Sendable
		func container() throws -> CKContainer {
			print("•••• cloudContainer: \(cloudContainer.containerIdentifier ?? "nil")")
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
		func extractProfile(_ record: CKRecord) throws -> BackedupProfile {
			guard record.recordType == .profile else {
				throw IncorrectRecordTypeError()
			}
			guard let asset = record[.content] as? CKAsset, let fileURL = asset.fileURL else {
				throw NoProfileInRecordError()
			}

			let data = try Data(contentsOf: fileURL)
			let containsLegacyP2PLinks = Profile.checkIfProfileJsonContainsLegacyP2PLinks(contents: data)
			let profile = try Profile(jsonData: data)
			try FileManager.default.removeItem(at: fileURL)

			return BackedupProfile(profile: profile, containsLegacyP2PLinks: containsLegacyP2PLinks)
		}

		@discardableResult
		@Sendable
		func uploadProfileToICloud(_ profile: Profile, existingRecord: CKRecord?) async throws -> CKRecord {
			try await uploadProfileSnapshotToICloud(profile.profileSnapshot(), id: profile.id, existingRecord: existingRecord)
		}

		@discardableResult
		@Sendable
		func uploadProfileSnapshotToICloud(_ profileSnapshot: Data, id: ProfileID, existingRecord: CKRecord?) async throws -> CKRecord {
			let fileManager = FileManager.default
			let tempDirectoryURL = fileManager.temporaryDirectory
			let fileURL = tempDirectoryURL.appendingPathComponent(UUID().uuidString)
			try profileSnapshot.write(to: fileURL)

			let record = existingRecord ?? .init(recordType: .profile, recordID: .init(recordName: id.uuidString))
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
				loggerGlobal.error("Automatic cloud backup failed with error \(error)")
				result = .failure
			}

			try? userDefaults.setLastCloudBackup(result, of: profile)
		}

		return .init(
			startAutomaticBackups: {
				let timer = AsyncTimerSequence(every: .seconds(60))
				let profiles = await profileStore.values()

				for try await (profile, _) in combineLatest(profiles, timer) {
					guard !Task.isCancelled else { return }
					guard profile.appPreferences.security.isCloudProfileSyncEnabled else { continue }
					guard profile.isNonEmpty else { continue }

					let last = userDefaults.getLastCloudBackups[profile.id]
					if let last, last.result == .success, last.profileHash == profile.hashValue { continue }

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

				return try await headerList.ids.asyncCompactMap { id -> CKRecord? in
					guard id != activeProfile else {
						// No need to migrate the currently active profile
						return nil
					}

					guard let profileSnapshot = try secureStorageClient.loadProfileSnapshotData(id) else {
						throw ProfileMissingFromKeychainError(id: id)
					}

					let profile = try Profile(jsonData: profileSnapshot)

					guard !profile.networks.isEmpty, profile.appPreferences.security.isCloudProfileSyncEnabled else {
						return nil
					}
					let backedUpRecord = backedUpRecords.first { $0.recordID.recordName == id.uuidString }

					if let backedUpRecord, let backedUp = try? extractProfile(backedUpRecord).profile, backedUp.header.lastModified >= profile.header.lastModified {
						return nil
					}

					return try await uploadProfileSnapshotToICloud(profileSnapshot, id: profile.id, existingRecord: backedUpRecord)
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
				try await fetchAllProfileRecords()
					.compactMap { try? extractProfile($0) }
					.filter(\.profile.isNonEmpty)
			}
		)
	}
}

extension Profile {
	var isNonEmpty: Bool {
		header.contentHint.numberOfAccountsOnAllNetworksInTotal + header.contentHint.numberOfPersonasOnAllNetworksInTotal > 0
	}
}
