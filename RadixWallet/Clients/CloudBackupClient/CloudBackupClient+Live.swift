import CloudKit
import ComposableArchitecture
import DependenciesAdditions
import os

extension CKRecord.RecordType {
	static let profile = "Profile"
}

extension CKRecord.FieldKey {
	static let content = "content"

	static let snapshotVersion = "snapshotVersion"
	static let creatingDeviceID = "creatingDeviceID"
	static let lastUsedOnDeviceID = "lastUsedOnDeviceID"
	static let lastModified = "lastModified"
	static let numberOfPersonas = "numberOfPersonas"
	static let numberOfAccounts = "numberOfAccounts"
}

extension [CKRecord.FieldKey] {
	static let metadata: Self = [
		.snapshotVersion,
		.creatingDeviceID,
		.lastUsedOnDeviceID,
		.lastModified,
		.numberOfPersonas,
		.numberOfAccounts,
	]
}

extension CloudBackupClient {
	struct IncorrectRecordTypeError: Error {}
	struct NoProfileInRecordError: Error {}
	struct MissingMetadataError: Error {}
	struct HeaderAndMetadataMismatchError: Error {}
	struct ProfileMissingFromKeychainError: Error { let id: ProfileID }

	public static let liveValue: Self = .live()

	public static func live(
		profileStore: ProfileStore = .shared
	) -> CloudBackupClient {
		@Dependency(\.secureStorageClient) var secureStorageClient
		@Dependency(\.userDefaults) var userDefaults

		let container: CKContainer = .default()

		@Sendable
		func fetchProfileRecord(_ id: CKRecord.ID) async throws -> CKRecord {
			try await container.privateCloudDatabase.record(for: id)
		}

		@Sendable
		func fetchAllProfileRecords(metadataOnly: Bool = false) async throws -> [CKRecord] {
			let records = try await container.privateCloudDatabase.records(
				matching: .init(recordType: .profile, predicate: .init(value: true)),
				desiredKeys: metadataOnly ? .metadata : nil
			)
			return try records.matchResults.map { try $0.1.get() }
		}

		@Sendable
		func getMetadata(_ record: CKRecord) throws -> ProfileMetadata {
			guard let snapshotVersion = (record[.snapshotVersion] as? UInt16).flatMap(ProfileSnapshotVersion.init(rawValue:)),
			      let creatingDeviceID = (record[.creatingDeviceID] as? String).flatMap(UUID.init),
			      let lastUsedOnDeviceID = (record[.lastUsedOnDeviceID] as? String).flatMap(UUID.init),
			      let lastModified = record[.lastModified] as? Date,
			      let numberOfPersonas = record[.numberOfPersonas] as? UInt16,
			      let numberOfAccounts = record[.numberOfAccounts] as? UInt16
			else {
				throw MissingMetadataError()
			}

			return .init(
				snapshotVersion: snapshotVersion,
				creatingDeviceID: creatingDeviceID,
				lastUsedOnDeviceID: lastUsedOnDeviceID,
				lastModified: lastModified,
				numberOfPersonas: numberOfPersonas,
				numberOfAccounts: numberOfAccounts
			)
		}

		@Sendable
		func setMetadata(_ metadata: ProfileMetadata, on record: CKRecord) {
			record[.snapshotVersion] = metadata.snapshotVersion.rawValue
			record[.creatingDeviceID] = metadata.creatingDeviceID.uuidString
			record[.lastUsedOnDeviceID] = metadata.lastUsedOnDeviceID.uuidString
			record[.lastModified] = metadata.lastModified
			record[.numberOfPersonas] = metadata.numberOfPersonas
			record[.numberOfAccounts] = metadata.numberOfAccounts
		}

		@Sendable
		func extractProfile(_ record: CKRecord) throws -> BackedupProfile {
			guard record.recordType == .profile else {
				throw IncorrectRecordTypeError()
			}
			guard let asset = record[.content] as? CKAsset, let fileURL = asset.fileURL else {
				throw NoProfileInRecordError()
			}

			let data_ = try String(contentsOf: fileURL, encoding: .utf8)
			print("••• READ \(data_)")
			let profile_ = try Profile(jsonString: data_)
			//			print("••• \(profile == profile_)")

			let data = try Data(contentsOf: fileURL)
			let containsLegacyP2PLinks = Profile.checkIfProfileJsonContainsLegacyP2PLinks(contents: data)
			let profile = try Profile(jsonData: data)
			try FileManager.default.removeItem(at: fileURL)

			guard try getMetadata(record) == profile.header.metadata else {
				throw HeaderAndMetadataMismatchError()
			}

			return BackedupProfile(profile: profile, containsLegacyP2PLinks: containsLegacyP2PLinks)
		}

		@discardableResult
		@Sendable
		func uploadProfileToICloud(_ profile: Profile, existingRecord: CKRecord?) async throws -> CKRecord {
			try await uploadProfileSnapshotToICloud(profile.profileSnapshot(), header: profile.header, existingRecord: existingRecord)
		}

		@discardableResult
		@Sendable
		func uploadProfileSnapshotToICloud(_ profileSnapshot: Data, header: Profile.Header, existingRecord: CKRecord?) async throws -> CKRecord {
			let fileManager = FileManager.default
			let tempDirectoryURL = fileManager.temporaryDirectory
			let fileURL = tempDirectoryURL.appendingPathComponent(UUID().uuidString)
			try profileSnapshot.write(to: fileURL)

			let id = header.id
			let record = existingRecord ?? .init(recordType: .profile, recordID: .init(recordName: id.uuidString))
			record[.content] = CKAsset(fileURL: fileURL)

			setMetadata(header.metadata, on: record)

			let savedRecord = try await container.privateCloudDatabase.save(record)
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
					guard profile.header.isNonEmpty else { continue }

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

				return try await headerList.elements.asyncCompactMap { header -> CKRecord? in
					let id = header.id
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

					if let backedUpRecord, try extractProfile(backedUpRecord).profile.header.lastModified >= profile.header.lastModified {
						return nil
					}

					return try await uploadProfileSnapshotToICloud(profileSnapshot, header: header, existingRecord: backedUpRecord)
				}
			},
			deleteProfileBackup: { id in
				try await container.privateCloudDatabase.deleteRecord(withID: .init(recordName: id.uuidString))
				try userDefaults.removeLastCloudBackup(for: id)
			},
			checkAccountStatus: {
				try await container.accountStatus()
			},
			lastBackup: { id in
				userDefaults.lastCloudBackupValues(for: id)
			},
			loadProfile: { id in
				try await extractProfile(fetchProfileRecord(.init(recordName: id.uuidString)))
			},
			loadAllProfiles: {
				try await fetchAllProfileRecords()
					.map(extractProfile)
					.filter(\.profile.header.isNonEmpty)
			}
		)
	}
}

private extension Profile.Header {
	var isNonEmpty: Bool {
		contentHint.numberOfAccountsOnAllNetworksInTotal + contentHint.numberOfPersonasOnAllNetworksInTotal > 0
	}

	var metadata: CloudBackupClient.ProfileMetadata {
		.init(
			snapshotVersion: snapshotVersion,
			creatingDeviceID: creatingDevice.id,
			lastUsedOnDeviceID: lastUsedOnDevice.id,
			lastModified: lastModified,
			numberOfPersonas: contentHint.numberOfPersonasOnAllNetworksInTotal,
			numberOfAccounts: contentHint.numberOfAccountsOnAllNetworksInTotal
		)
	}
}
