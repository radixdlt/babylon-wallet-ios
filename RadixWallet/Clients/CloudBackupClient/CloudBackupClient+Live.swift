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
	struct HeaderAndMetadataMismatchError: Error {}
	struct WrongRecordTypeError: Error { let type: CKRecord.RecordType }
	struct ProfileMissingFromKeychainError: Error { let id: ProfileID }

	public static let liveValue: Self = .live()

	public static func live(
		profileStore: ProfileStore = .shared
	) -> CloudBackupClient {
		@Dependency(\.overlayWindowClient) var overlayWindowClient
		@Dependency(\.secureStorageClient) var secureStorageClient
		@Dependency(\.userDefaults) var userDefaults

		let container: CKContainer = .default()

		@Sendable
		func fetchProfileRecord(_ id: CKRecord.ID) async throws -> CKRecord {
			let record = try await container.privateCloudDatabase.record(for: id)
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

			guard try getProfileHeader(record).isEquivalent(to: profile.header) else {
				throw HeaderAndMetadataMismatchError()
			}

			return BackedUpProfile(profile: profile, containsLegacyP2PLinks: containsLegacyP2PLinks)
		}

		@discardableResult
		@Sendable
		func uploadProfileToICloud(_ profile: Either<Data, String>, header: Profile.Header, existingRecord: CKRecord?) async throws -> CKRecord {
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
		func backupProfileAndSaveResult(_ profile: Profile) async {
			let existingRecord = try? await fetchProfileRecord(.init(recordName: profile.id.uuidString))
			let result: BackupResult.Result
			do {
				let json = profile.toJSONString()
				try await uploadProfileToICloud(.right(json), header: profile.header, existingRecord: existingRecord)
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
				let ticks = AsyncTimerSequence(every: .seconds(1))
				let profiles = await profileStore.values()
				var lastClaimCheck: Date = .now // .distantPast

				print("•• START automaticBackups")
				for try await (profile, tick) in combineLatest(profiles, ticks) {
					guard !Task.isCancelled else { print("•• CANCEL automaticBackups"); return }

					print("•• tick")

					if tick.timeIntervalSince(lastClaimCheck) > 15 {
						print("•• time to check claims")
						lastClaimCheck = tick

						let backedUpHeader = try? await getProfileHeader(fetchProfileRecord(.init(recordName: profile.id.uuidString)))

						if true /* let backedUpHeader, await !profileStore.isThisDevice(deviceID: backedUpHeader.lastUsedOnDevice.id) */ {
							print("•• different IDs")

							print("•• show fullscreen")

							let action = await overlayWindowClient.scheduleFullScreen(.init(root: .claimWallet(.init())))

							print("•• got fullscreen action \(action)")

						} else {
							print("•• same IDs")
						}
					}

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

				let previouslyMigrated = userDefaults.getMigratedKeychainProfiles

				let migratable = try headerList.compactMap { header -> (Data, Profile.Header)? in
					let id = header.id

					guard !previouslyMigrated.contains(id), header.id != activeProfile else { return nil }

					guard let profileData = try secureStorageClient.loadProfileSnapshotData(id) else {
						throw ProfileMissingFromKeychainError(id: id)
					}

					let profile = try Profile(jsonData: profileData)
					guard !profile.networks.isEmpty else { return nil }
					guard profile.appPreferences.security.isCloudProfileSyncEnabled else { return nil }

					return (profileData, header)
				}

				let migrated = try await migratable.asyncMap { profileData, header in
					let backedUpRecord = backedUpRecords.first { $0.recordID.recordName == header.id.uuidString }
					if let backedUpRecord, try getProfileHeader(backedUpRecord).lastModified >= header.lastModified {
						// We already have a more recent version backed up on iCloud, so we return that
						return backedUpRecord
					}

					let uploadedRecord = try await uploadProfileToICloud(.left(profileData), header: header, existingRecord: backedUpRecord)
					try secureStorageClient.updateIsCloudProfileSyncEnabled(header.id, .disable)

					return uploadedRecord
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

	func isEquivalent(to other: Self) -> Bool {
		snapshotVersion.rawValue == other.snapshotVersion.rawValue &&
			creatingDevice.isEquivalent(to: other.creatingDevice) &&
			lastUsedOnDevice.isEquivalent(to: other.lastUsedOnDevice) &&
			lastModified.isEquivalent(to: other.lastModified) &&
			contentHint.numberOfAccountsOnAllNetworksInTotal == other.contentHint.numberOfAccountsOnAllNetworksInTotal &&
			contentHint.numberOfPersonasOnAllNetworksInTotal == other.contentHint.numberOfPersonasOnAllNetworksInTotal &&
			contentHint.numberOfNetworks == other.contentHint.numberOfNetworks
	}
}

private extension DeviceInfo {
	func isEquivalent(to other: Self) -> Bool {
		id.uuidString == other.id.uuidString &&
			date.isEquivalent(to: other.date) &&
			description == other.description
	}
}

private extension Date {
	func isEquivalent(to other: Self) -> Bool {
		abs(timeIntervalSince(other)) < 0.001
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
