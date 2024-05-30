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
	static let creatingDeviceDate = "creatingDeviceDate"
	static let creatingDeviceDescription = "creatingDeviceDescription"

	static let lastUsedOnDeviceID = "lastUsedOnDeviceID"
	static let lastUsedOnDeviceDate = "lastUsedOnDeviceDate"
	static let lastUsedOnDeviceDescription = "lastUsedOnDeviceDescription"

	static let lastModified = "lastModified"
	static let numberOfAccounts = "numberOfAccounts"
	static let numberOfPersonas = "numberOfPersonas"
	static let numberOfNetworks = "numberOfNetworks"
}

extension [CKRecord.FieldKey] {
	static let header: Self = [
		.snapshotVersion,
		.creatingDeviceID,
		.creatingDeviceDate,
		.creatingDeviceDescription,
		.lastUsedOnDeviceID,
		.lastUsedOnDeviceDate,
		.lastUsedOnDeviceDescription,
		.lastModified,
		.numberOfAccounts,
		.numberOfPersonas,
		.numberOfNetworks,
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
		func fetchAllProfileRecords(headerOnly: Bool = false) async throws -> [CKRecord] {
			let records = try await container.privateCloudDatabase.records(
				matching: .init(recordType: .profile, predicate: .init(value: true)),
				desiredKeys: headerOnly ? .header : nil
			)
			return try records.matchResults.map { try $0.1.get() }
		}

		@Sendable
		func getProfile(_ record: CKRecord) throws -> BackedUpProfile {
			guard record.recordType == .profile else {
				throw IncorrectRecordTypeError()
			}
			guard let asset = record[.content] as? CKAsset, let fileURL = asset.fileURL else {
				throw NoProfileInRecordError()
			}

			let json = try String(contentsOf: fileURL, encoding: .utf8)
			let containsLegacyP2PLinks = Profile.checkIfProfileJsonStringContainsLegacyP2PLinks(jsonString: json)
			let profile = try Profile(jsonString: json)
			try FileManager.default.removeItem(at: fileURL)

			guard try getProfileHeader(record) == profile.header else {
				throw HeaderAndMetadataMismatchError()
			}

			return BackedUpProfile(profile: profile, containsLegacyP2PLinks: containsLegacyP2PLinks)
		}

		@discardableResult
		@Sendable
		func uploadProfileSnapshotToICloud(_ snapshot: Data, header: Profile.Header, existingRecord: CKRecord?) async throws -> CKRecord {
			let fileManager = FileManager.default
			let tempDirectoryURL = fileManager.temporaryDirectory
			let fileURL = tempDirectoryURL.appendingPathComponent(UUID().uuidString)
			try snapshot.write(to: fileURL)

			let id = header.id
			let record = existingRecord ?? .init(recordType: .profile, recordID: .init(recordName: id.uuidString))
			record[.content] = CKAsset(fileURL: fileURL)

			setProfileHeader(header, on: record)

			let savedRecord = try await container.privateCloudDatabase.save(record)
			try fileManager.removeItem(at: fileURL)

			return savedRecord
		}

		@Sendable
		func backupProfileAndSaveResult(_ profile: Profile) async {
			let existingRecord = try? await fetchProfileRecord(.init(recordName: profile.id.uuidString))
			let result: BackupResult.Result
			do {
				try await uploadProfileSnapshotToICloud(
					profile.profileSnapshot(),
					header: profile.header,
					existingRecord: existingRecord
				)
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

					if let backedUpRecord, let header = try? getProfileHeader(backedUpRecord), header.lastModified >= profile.header.lastModified {
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
				try await getProfile(fetchProfileRecord(.init(recordName: id.uuidString)))
			},
			loadProfileHeaders: {
				try await fetchAllProfileRecords(headerOnly: true)
					.map(getProfileHeader)
					.filter(\.isNonEmpty)
			}
		)
	}
}

private extension Profile.Header {
	var isNonEmpty: Bool {
		contentHint.numberOfAccountsOnAllNetworksInTotal + contentHint.numberOfPersonasOnAllNetworksInTotal > 0
	}
}

extension CloudBackupClient {
	@Sendable
	private static func getProfileHeader(_ record: CKRecord) throws -> Profile.Header {
		guard let snapshotVersion = (record[.snapshotVersion] as? UInt16).flatMap(ProfileSnapshotVersion.init(rawValue:)),
		      let id = UUID(uuidString: record.recordID.recordName),
		      let creatingDeviceID = (record[.creatingDeviceID] as? String).flatMap(UUID.init),
		      let creatingDeviceDate = (record[.creatingDeviceDate] as? Date),
		      let creatingDeviceDescription = (record[.creatingDeviceDescription] as? String),
		      let lastUsedOnDeviceID = (record[.lastUsedOnDeviceID] as? String).flatMap(UUID.init),
		      let lastUsedOnDeviceDate = (record[.lastUsedOnDeviceDate] as? Date),
		      let lastUsedOnDeviceDescription = (record[.lastUsedOnDeviceDescription] as? String),
		      let lastModified = record[.lastModified] as? Date,
		      let numberOfAccounts = record[.numberOfAccounts] as? UInt16,
		      let numberOfPersonas = record[.numberOfPersonas] as? UInt16,
		      let numberOfNetworks = record[.numberOfNetworks] as? UInt16
		else {
			throw MissingMetadataError()
		}

		return .init(
			snapshotVersion: snapshotVersion,
			id: id,
			creatingDevice: .init(
				id: creatingDeviceID,
				date: creatingDeviceDate,
				description: creatingDeviceDescription
			),
			lastUsedOnDevice: .init(
				id: lastUsedOnDeviceID,
				date: lastUsedOnDeviceDate,
				description: lastUsedOnDeviceDescription
			),
			lastModified: lastModified,
			contentHint: .init(
				numberOfAccountsOnAllNetworksInTotal: numberOfAccounts,
				numberOfPersonasOnAllNetworksInTotal: numberOfPersonas,
				numberOfNetworks: numberOfNetworks
			)
		)
	}

	@Sendable
	private static func setProfileHeader(_ header: Profile.Header, on record: CKRecord) {
		record[.snapshotVersion] = header.snapshotVersion.rawValue
		record[.creatingDeviceID] = header.creatingDevice.id.uuidString
		record[.creatingDeviceDate] = header.creatingDevice.date
		record[.creatingDeviceDescription] = header.creatingDevice.description
		record[.lastUsedOnDeviceID] = header.lastUsedOnDevice.id.uuidString
		record[.lastUsedOnDeviceDate] = header.lastUsedOnDevice.date
		record[.lastUsedOnDeviceDescription] = header.lastUsedOnDevice.description
		record[.lastModified] = header.lastModified
		record[.numberOfAccounts] = header.contentHint.numberOfAccountsOnAllNetworksInTotal
		record[.numberOfPersonas] = header.contentHint.numberOfPersonasOnAllNetworksInTotal
		record[.numberOfNetworks] = header.contentHint.numberOfNetworks
	}
}
