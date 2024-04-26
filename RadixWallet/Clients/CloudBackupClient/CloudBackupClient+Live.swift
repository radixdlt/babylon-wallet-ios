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
	struct MissingProfileError: Error {}

	public static let liveValue: Self = .live()

	private static let container = CKContainer(identifier: "iCloud.com.radixpublishing.radixwallet.ios.dev.cloudBackup")

	public func loadBackedUpProfileHeaderList() async -> ProfileSnapshot.HeaderList? {
		try? await .init(rawValue: loadAllProfiles().map(\.header).asIdentified())
	}

	public static func live(
		profileStore: ProfileStore = .shared
	) -> CloudBackupClient {
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
				throw MissingProfileError()
			}

			let data = try Data(contentsOf: fileURL)
			let profile = try JSONDecoder().decode(Profile.self, from: data)
			try FileManager.default.removeItem(at: fileURL)

			return profile
		}

		@Sendable
		func saveProfile(_ profile: Profile, existingRecord: CKRecord?) async throws -> CKRecord {
			print("  •• uploadProfile (exists: \(existingRecord != nil)) \(profile.id.uuidString)")
			let fileManager = FileManager.default
			let tempDirectoryURL = fileManager.temporaryDirectory
			let fileURL = tempDirectoryURL.appendingPathComponent(UUID().uuidString)
			try JSONEncoder().encode(profile).write(to: fileURL)

			let record = existingRecord ?? .init(recordType: .profile, recordID: .init(recordName: profile.id.uuidString))
			record[.content] = CKAsset(fileURL: fileURL)

			let savedRecord = try await container.privateCloudDatabase.save(record)
			try fileManager.removeItem(at: fileURL)

			print("  •• uploadProfile DONE")

			return savedRecord
		}

		return .init(
			migrateKeychainProfiles: {
				@Dependency(\.secureStorageClient) var secureStorageClient

				let p = await ProfileStore.shared.profile
				print("•• Current profile \(p.id.uuidString)")

				let backedUpRecords = try await fetchAllProfileRecords()
				let headerList = try secureStorageClient.loadProfileHeaderList()
				let ids = headerList?.ids ?? []

				return try await ids.asyncCompactMap { id in
					print("•• Migrating \(id.uuidString)")

					guard let profile = try secureStorageClient.loadProfile(id) else {
						return nil // FIXME: GK - or throw?
					}
					guard profile.appPreferences.security.isCloudProfileSyncEnabled else {
						print("  •• cloud sync disabled for \(id.uuidString)")
						return nil
					}
					let backedUpRecord = backedUpRecords.first { $0.recordID.recordName == id.uuidString }

					if let backedUpRecord, try extractProfile(backedUpRecord).header.lastModified >= profile.header.lastModified {
						print("  •• already backed up \(id.uuidString)")
						return nil
					}

					return try await saveProfile(profile, existingRecord: backedUpRecord)
					// FIXME: GK - remove from keychain?
				}
			},
			checkAccountStatus: {
				try await container.accountStatus()
			},
			lastBackup: { id in
				try await fetchProfileRecord(.init(recordName: id.uuidString)).modificationDate
			},
			loadProfile: { id in
				try await extractProfile(fetchProfileRecord(.init(recordName: id.uuidString)))
			},
			loadAllProfiles: {
				try await fetchAllProfileRecords().map(extractProfile)
			},
			backupProfile: { profile in
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
			},
			deleteProfile: { id in
				try await container.privateCloudDatabase.deleteRecord(withID: .init(recordName: id.uuidString))
			}
		)
	}
}
