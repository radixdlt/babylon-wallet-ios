import CloudKit
import ComposableArchitecture
import DependenciesAdditions
import os

extension CKRecord.RecordType {
	static let profile = "ProfileV2"
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
	struct WrongRecordTypeError: Error { let type: CKRecord.RecordType }
	struct FailedToClaimProfileError: Error { let error: Error }

	public static let liveValue: Self = .live()

	public static func live(
		profileStore: ProfileStore = .shared
	) -> CloudBackupClient {
		@Dependency(\.overlayWindowClient) var overlayWindowClient
		@Dependency(\.secureStorageClient) var secureStorageClient
		@Dependency(\.userDefaults) var userDefaults

		let container: CKContainer = .default()

		@Sendable
		func fetchProfileRecord(_ id: ProfileID) async throws -> CKRecord {
			let recordID = CKRecord.ID(recordName: id.uuidString)
			let record = try await container.privateCloudDatabase.record(for: recordID)
			guard record.recordType == .profile else {
				throw WrongRecordTypeError(type: record.recordType)
			}
			return record
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

			return BackedUpProfile(profile: profile, containsLegacyP2PLinks: containsLegacyP2PLinks)
		}

		@discardableResult
		@Sendable
		func backupProfile(_ profile: Either<Data, String>, header: Profile.Header, existingRecord: CKRecord?) async throws -> CKRecord {
			let fileManager = FileManager.default
			let tempDirectoryURL = fileManager.temporaryDirectory
			let fileURL = tempDirectoryURL.appendingPathComponent(UUID().uuidString)
			switch profile {
			case let .left(data):
				try data.write(to: fileURL)
			case let .right(json):
				try json.write(to: fileURL, atomically: true, encoding: .utf8)
			}

			let id = header.id
			let record = existingRecord ?? .init(recordType: .profile, recordID: .init(recordName: id.uuidString))
			record[.content] = CKAsset(fileURL: fileURL)
			setProfileHeader(header, on: record)
			let savedRecord = try await container.privateCloudDatabase.save(record)
			try fileManager.removeItem(at: fileURL)

			return savedRecord
		}

		@Sendable
		func backupProfileAndSaveResult(_ profile: Profile, existingRecord: CKRecord?) async throws {
			do {
				let json = profile.toJSONString()
				try await backupProfile(.right(json), header: profile.header, existingRecord: existingRecord)
			} catch {
				let failure: BackupResult.Result.Failure
				switch error {
				case CKError.accountTemporarilyUnavailable:
					failure = .temporarilyUnavailable
				case CKError.notAuthenticated:
					failure = .notAuthenticated
				default:
					loggerGlobal.error("Automatic cloud backup failed with error \(error)")
					failure = .other
				}

				try? userDefaults.setLastCloudBackup(.failure(failure), of: profile)
				throw error
			}

			try? userDefaults.setLastCloudBackup(.success, of: profile)
		}

		@Sendable
		func performAutomaticBackup(_ profile: Profile, timeToCheckIfClaimed: Bool) async {
			let needsBackUp = profile.appPreferences.security.isCloudProfileSyncEnabled && profile.header.isNonEmpty
			let lastBackup = userDefaults.getLastCloudBackups[profile.id]
			let lastBackupSucceeded = lastBackup?.result == .success && lastBackup?.saveIdentifier == profile.saveIdentifier

			let shouldBackUp = needsBackUp && !lastBackupSucceeded
			let shouldCheckClaim = shouldBackUp || timeToCheckIfClaimed

			guard shouldBackUp || shouldCheckClaim else { return }

			let existingRecord = try? await fetchProfileRecord(profile.id)

			let backedUpID = try? existingRecord.map(getProfileHeader)?.lastUsedOnDevice.id

			let shouldReclaim: Bool
			if shouldCheckClaim, let backedUpID, await !profileStore.isThisDevice(deviceID: backedUpID) {
				let action = await overlayWindowClient.scheduleFullScreen(.init(root: .claimWallet(.init())))
				shouldReclaim = action == .claimWallet(.transferBack)
			} else {
				shouldReclaim = false
			}

			guard shouldBackUp || shouldReclaim else { return }

			try? await backupProfileAndSaveResult(profile, existingRecord: existingRecord)
		}

		let retryBackupInterval: DispatchTimeInterval = .seconds(60)
		let checkClaimedProfileInterval: TimeInterval = 15 * 60

		return .init(
			startAutomaticBackups: {
				// The active profile should not be synced to iCloud keychain
				let profileID = await profileStore.profile.id
				try secureStorageClient.disableCloudProfileSync(profileID)

				let ticks = AsyncTimerSequence(every: retryBackupInterval)
				let profiles = await profileStore.values()
				var lastClaimCheck: Date = .distantPast

				for try await (profile, tick) in combineLatest(profiles, ticks) {
					guard !Task.isCancelled else { return }

					// This will skip the ticks that get backed up while we are awaiting performAutomaticBackup
					guard tick > lastClaimCheck else { continue }
					if tick.timeIntervalSince(lastClaimCheck) > checkClaimedProfileInterval {
						await performAutomaticBackup(profile, timeToCheckIfClaimed: true)
						lastClaimCheck = .now
					} else {
						await performAutomaticBackup(profile, timeToCheckIfClaimed: false)
					}
				}
			},
			migrateProfilesFromKeychain: {
				let activeProfile = await profileStore.profile.id
				let backedUpRecords = try await fetchAllProfileRecords()
				guard let headerList = try secureStorageClient.loadProfileHeaderList() else { return [] }

				let previouslyMigrated = userDefaults.getMigratedKeychainProfiles

				let migratable = try headerList.compactMap { header -> (Data, Profile.Header)? in
					let id = header.id
					guard !previouslyMigrated.contains(id), header.id != activeProfile else { return nil }

					guard let profileData = try? secureStorageClient.loadProfileSnapshotData(id) else { return nil }

					let profile = try Profile(jsonData: profileData)
					guard !profile.networks.isEmpty else { return nil }
					guard profile.appPreferences.security.isCloudProfileSyncEnabled else { return nil }

					return (profileData, header)
				}

				let migrated: [CKRecord] = try await migratable.asyncCompactMap { profileData, header in
					let backedUpRecord = backedUpRecords.first { $0.recordID.recordName == header.id.uuidString }
					if let backedUpRecord, try getProfileHeader(backedUpRecord).lastModified >= header.lastModified {
						// We already have a more recent version backed up on iCloud
						return nil
					}

					return try await backupProfile(.left(profileData), header: header, existingRecord: backedUpRecord)
				}

				let migratedIDs = migrated.compactMap { ProfileID(uuidString: $0.recordID.recordName) }
				try userDefaults.appendMigratedKeychainProfiles(migratedIDs)

				return migrated
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
				try await getProfile(fetchProfileRecord(id))
			},
			loadProfileHeaders: {
				try await fetchAllProfileRecords(headerOnly: true)
					.map(getProfileHeader)
					.filter(\.isNonEmpty)
			},
			claimProfileOnICloud: { profile in
				let existingRecord = try? await fetchProfileRecord(profile.id)
				do {
					try await backupProfileAndSaveResult(profile, existingRecord: existingRecord)
				} catch {
					throw FailedToClaimProfileError(error: error)
				}
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
