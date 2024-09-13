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
	public func deleteProfileBackup() async throws {
		try await deleteProfileBackup(nil)
	}
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
		@Dependency(\.appPreferencesClient) var appPreferencesClient
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
		func fetchAllProfileHeaders() async throws -> [CKRecord] {
			let records = try await container.privateCloudDatabase.records(
				matching: .init(recordType: .profile, predicate: .init(value: true)),
				desiredKeys: .header
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
			try? userDefaults.setLastCloudBackup(.started(.now), of: profile.header)

			do {
				let json = profile.toJSONString()
				try await backupProfile(.right(json), header: profile.header, existingRecord: existingRecord)
			} catch {
				if await (try? container.accountStatus()) == .restricted {
					try await appPreferencesClient.setIsCloudBackupEnabled(false)
				}

				let failure: BackupResult.Result.Failure
				switch error {
				case CKError.accountTemporarilyUnavailable:
					failure = .temporarilyUnavailable
				case CKError.notAuthenticated:
					failure = .notAuthenticated
				default:
					loggerGlobal.error("Cloud backup failed with error \(error)")
					failure = .other
				}

				try? userDefaults.setLastCloudBackup(.failure(failure), of: profile.header)
				throw error
			}

			try? userDefaults.setLastCloudBackup(.success, of: profile.header)
		}

		@Sendable
		func performAutomaticBackup(_ profile: Profile, timeToCheckIfClaimed: Bool) async {
			let existingRecord = try? await fetchProfileRecord(profile.id)
			let backedUpHeader = try? existingRecord.map(getProfileHeader)

			if let backedUpHeader, let backupDate = existingRecord?.modificationDate {
				try? userDefaults.setLastCloudBackup(.success, of: backedUpHeader, at: backupDate)
			} else {
				try? userDefaults.removeLastCloudBackup(for: profile.id)
			}

			guard profile.appPreferences.security.isCloudProfileSyncEnabled else { return }
			let isBackedUp = backedUpHeader?.saveIdentifier == profile.header.saveIdentifier
			let shouldBackUp = profile.header.isNonEmpty && !isBackedUp

			guard shouldBackUp || timeToCheckIfClaimed else { return }

			let shouldReclaim: Bool
			if let backedUpID = backedUpHeader?.lastUsedOnDevice.id, await !profileStore.isThisDevice(deviceID: backedUpID) {
				let action = await overlayWindowClient.scheduleFullScreen(.init(root: .claimWallet(.init())))
				switch action {
				case .claimWallet(.transferBack):
					shouldReclaim = true
				case .claimWallet(.didClearWallet), .dismiss:
					return
				}
			} else {
				shouldReclaim = false
			}

			guard shouldBackUp || shouldReclaim else { return }

			try? await backupProfileAndSaveResult(profile, existingRecord: existingRecord)
		}

		let retryBackupInterval: DispatchTimeInterval = .seconds(60)
		let checkClaimedProfileInterval: TimeInterval = 15 * 60

		return .init(
			isCloudProfileSyncEnabled: {
				await profileStore.appPreferencesValues()
					.map(\.security.isCloudProfileSyncEnabled)
					.removeDuplicates()
					.eraseToAnyAsyncSequence()
			},
			startAutomaticBackups: {
				// The active profile should not be synced to iCloud keychain
				let profileID = await profileStore.profile().id
				try secureStorageClient.disableCloudProfileSync(profileID)

				let ticks = AsyncTimerSequence(every: retryBackupInterval)
				let profiles = await profileStore.values()
				var lastClaimCheck: Date = .distantPast

				let iCloudAvailability = NotificationCenter.default.notifications(named: .NSUbiquityIdentityDidChange)
					.map { _ in () }.prepend(())
				let cloudKitStatus = NotificationCenter.default.notifications(named: .CKAccountChanged)
					.map { _ in () }.prepend(())
				let iCloudStatus = combineLatest(iCloudAvailability, cloudKitStatus)
					.map { _, _ in () }

				for try await (profile, tick, _) in combineLatest(profiles, ticks, iCloudStatus) {
					guard !Task.isCancelled else { return }
					if tick.timeIntervalSince(lastClaimCheck) > checkClaimedProfileInterval {
						await performAutomaticBackup(profile, timeToCheckIfClaimed: true)
						lastClaimCheck = .now
					} else {
						await performAutomaticBackup(profile, timeToCheckIfClaimed: false)
					}
				}
			},
			migrateProfilesFromKeychain: {
				guard let headerList = try secureStorageClient.loadProfileHeaderList() else { return [] }

				let previouslyMigrated = userDefaults.getMigratedKeychainProfiles

				let migratable = try headerList.compactMap { header -> (Data, Profile.Header)? in
					let id = header.id
					guard !previouslyMigrated.contains(id) else { return nil }

					guard let profileData = try? secureStorageClient.loadProfileSnapshotData(id) else { return nil }

					let profile = try Profile(jsonData: profileData)
					guard !profile.networks.isEmpty else { return nil }
					guard profile.appPreferences.security.isCloudProfileSyncEnabled else { return nil }

					return (profileData, header)
				}

				let backedUpRecords = try await fetchAllProfileHeaders()

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
			deleteProfileBackup: { optionalID in
				let activeProfileID = try await profileStore.profile().id
				let id = optionalID ?? activeProfileID
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
				try await fetchAllProfileHeaders()
					.map(getProfileHeader)
					.filter(\.isNonEmpty)
			},
			claimProfileOnICloud: { profile in
				let existingRecord = try? await fetchProfileRecord(profile.id)
				do {
					try await backupProfileAndSaveResult(profile, existingRecord: existingRecord)
				} catch {
					loggerGlobal.error("Failed to claim profile on iCloud \(error)")
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
