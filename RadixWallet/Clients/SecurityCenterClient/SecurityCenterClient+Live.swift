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

extension SecurityCenterClient {
	struct IncorrectRecordTypeError: Error {}
	struct MissingProfileError: Error {}

	public static let liveValue: Self = .live()

	private static let container = CKContainer(identifier: "iCloud.com.radixpublishing.radixwallet.ios.dev.cloudBackup")

	public static func live(
		profileStore: ProfileStore = .shared
	) -> CloudBackupClient {
		func fetchProfileRecord(_ id: CKRecord.ID) async throws -> CKRecord {
			try await container.privateCloudDatabase.record(for: id)
		}

		func extractProfile(_ record: CKRecord) throws -> Profile {
			guard record.recordType == .profile else {
				throw IncorrectRecordTypeError()
			}
			guard let asset = record[.content] as? CKAsset, let fileURL = asset.fileURL else {
				throw MissingProfileError()
			}

			let data = try Data(contentsOf: fileURL)
			let profile = try JSONDecoder().decode(Profile.self, from: data)
			print("•• got profile \(profile.id)")
			try FileManager.default.removeItem(at: fileURL)

			return profile
		}

		func uploadProfile(_ profile: Profile, existingRecord: CKRecord?) async throws -> CKRecord {
			print("•• uploadProfile (exists: \(existingRecord != nil)) \(profile.id.uuidString)")

			let fileManager = FileManager.default
			let tempDirectoryURL = fileManager.temporaryDirectory
			let fileURL = tempDirectoryURL.appendingPathComponent(UUID().uuidString)
			try JSONEncoder().encode(profile).write(to: fileURL)

			let record = existingRecord ?? .init(recordType: .profile, recordID: .init(recordName: profile.id.uuidString))
			record[.content] = CKAsset(fileURL: fileURL)

			let savedRecord = try await container.privateCloudDatabase.save(record)
			try fileManager.removeItem(at: fileURL)

			print("•• uploadProfile DONE")

			return savedRecord
		}

		return .init(
			checkAccountStatus: {
				try await CKContainer.default().accountStatus()
			},
			lastBackup: { id in
				try await fetchProfileRecord(.init(recordName: id.uuidString)).modificationDate
			},
			queryProfile: { id in
				let record = try await fetchProfileRecord(.init(recordName: id.uuidString))
				return try extractProfile(record)
			},
			queryAllProfiles: {
				let records = try await container.privateCloudDatabase.records(
					matching: .init(recordType: .profile, predicate: .init(value: true))
				)
				return try records.matchResults.map { result in
					try extractProfile(result.1.get())
				}
			},
			uploadProfile: { profile in
				print("•• uploadProfile \(profile.id.uuidString)")

				let existingRecord: CKRecord?

				do {
					existingRecord = try await fetchProfileRecord(.init(recordName: profile.id.uuidString))
					print("•• record found already, updating")
				} catch {
					let ckError = error as? CKError
					switch ckError?.code {
					case .unknownItem: // Item not in iCloud, create new
						existingRecord = nil
						print("•• record not found previously")
					default:
						print("•• uploadProfile FAILED other \(error)")
						throw error
					}
				}
				return try await uploadProfile(profile, existingRecord: existingRecord)

//				let existingRecord = try? await fetchProfileRecord(.init(recordName: profile.id.uuidString))
//				return try await uploadProfile(profile, existingRecord: existingRecord)

			},
			deleteProfile: { id in
				try await container.privateCloudDatabase.deleteRecord(withID: .init(recordName: id.uuidString))
			}
		)
	}
}
