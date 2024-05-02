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
	struct IncorrectRecordTypeError: Error {}
	struct NoProfileInRecordError: Error {}
	struct ProfileMissingFromKeychainError: Error { let id: UUID }

	public static let liveValue: Self = .live()

	private static let container = CKContainer(identifier: "iCloud.com.radixpublishing.radixwallet.ios.dev.cloudBackup")

	public static func live(
		profileStore: ProfileStore = .shared
	) -> CloudBackupClient {
		@Dependency(\.secureStorageClient) var secureStorageClient
		@Dependency(\.userDefaults) var userDefaults

		Task {
			for try await profile in await profileStore.values() {
				let existingRecord = try? await fetchProfileRecord(.init(recordName: profile.id.uuidString))
				let status: BackupMetadata.Status
				do {
					try await saveProfile(profile, existingRecord: existingRecord)
					status = .success
				} catch CKError.accountTemporarilyUnavailable {
					status = .notAuthorized
				} catch {
					status = .failure
				}
				try? userDefaults.setLastCloudBackup(status, of: profile)
			}
		}

		@Sendable
		func fetchProfileRecord(_ id: CKRecord.ID) async throws -> CKRecord {
			try await container.privateCloudDatabase.record(for: id)
		}

		@Sendable
		func fetchAllProfileRecords() async throws -> [CKRecord] {
			let records = try await container.privateCloudDatabase.records(
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
		func saveProfile(_ profile: Profile, existingRecord: CKRecord?) async throws -> CKRecord {
			let fileManager = FileManager.default
			let tempDirectoryURL = fileManager.temporaryDirectory
			let fileURL = tempDirectoryURL.appendingPathComponent(UUID().uuidString)
			try profile.jsonData().write(to: fileURL)

			let record = existingRecord ?? .init(recordType: .profile, recordID: .init(recordName: profile.id.uuidString))
			record[.content] = CKAsset(fileURL: fileURL)

			let savedRecord = try await container.privateCloudDatabase.save(record)
			try fileManager.removeItem(at: fileURL)

			print("  •• SAVED PROFILE")

			return savedRecord
		}

		return .init(
			loadDeviceID: {
				try? secureStorageClient.loadDeviceInfo()?.id
			},
			migrateProfilesFromKeychain: {
				let activeProfile = await profileStore.profile.id
				print("•• Current profile \(activeProfile.uuidString)")

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

					print("•• Migrating \(id.uuidString) synced: \(profile.appPreferences.security.isCloudProfileSyncEnabled), empty: \(profile.networks.isEmpty)")

					guard !profile.networks.isEmpty, profile.appPreferences.security.isCloudProfileSyncEnabled else {
						return nil
					}
					let backedUpRecord = backedUpRecords.first { $0.recordID.recordName == id.uuidString }

					if let backedUpRecord, try extractProfile(backedUpRecord).header.lastModified >= profile.header.lastModified {
						print("  •• already backed up \(id.uuidString)")
						return nil
					}

					let savedRecord = try await saveProfile(profile, existingRecord: backedUpRecord)
					// Migration completed, deleting old copy
//					try secureStorageClient.deleteProfile(profile.id)

					return savedRecord
				}
			},
			deleteProfileInKeychain: { id in
				try await container.privateCloudDatabase.deleteRecord(withID: .init(recordName: id.uuidString))
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
				try await fetchAllProfileRecords().map(extractProfile)
			},
			backupProfile: {
				let profile = await profileStore.profile
				print("•• backupProfile \(profile.id.uuidString)")
				let existingRecord: CKRecord?
				do {
					existingRecord = try await fetchProfileRecord(.init(recordName: profile.id.uuidString))
					print("  •• record found already, updating")
				} catch {
					let ckError = error as? CKError
					switch ckError?.code {
					case .unknownItem: // Item not in iCloud, create new
						existingRecord = nil
						print("  •• record not found previously")
					default:
						print("  •• uploadProfile FAILED other \(error)")
						throw error
					}
				}
				return try await saveProfile(profile, existingRecord: existingRecord)
				//				let existingRecord = try? await fetchProfileRecord(.init(recordName: profile.id.uuidString))
				//				return try await saveProfile(profile, existingRecord: existingRecord)
			}
		)
	}
}
