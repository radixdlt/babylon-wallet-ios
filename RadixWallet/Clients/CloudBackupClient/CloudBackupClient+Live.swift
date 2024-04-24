import CloudKit
import ComposableArchitecture
import DependenciesAdditions
import os

extension CKRecord.RecordType {
	static let profile = "ProfileV3"
}

extension CKRecord.FieldKey {
	static let content = "Content"
}

extension CloudBackupClient {
	public static let liveValue: Self = .live()

	public static func live(
		profileStore: ProfileStore = .shared
	) -> CloudBackupClient {
		func fetchProfileRecord(_ id: CKRecord.ID) async throws -> CKRecord {
			try await CKContainer.default().privateCloudDatabase.record(for: id)
		}

//		func upload(_ profile: Profile, existingRecord: CKRecord?) async throws -> CKRecord {
//			let fileManager = FileManager.default
//			let tempDirectoryURL = fileManager.temporaryDirectory
//			let fileURL = tempDirectoryURL.appendingPathComponent(UUID().uuidString)
//			try! JSONEncoder().encode(profile).write(to: fileURL)
//
//			let record = existingRecord ?? .init(recordType: .profile, recordID: .init(recordName: profile.id.uuidString))
//			record[.filenameProfileNotEncrypted]
//			record[.content] = CKAsset(fileURL: fileURL)
//
//			let savedRecord = try await CKContainer.default().privateCloudDatabase.save(record)
//			try fileManager.removeItem(at: fileURL)
//			return savedRecord
//		}

		return .init(
			checkAccountStatus: {
				try await CKContainer.default().accountStatus()
			},
			queryProfile: { id in
				try? await fetchProfileRecord(.init(recordName: id.uuidString))
			},
			uploadProfile: { profile in
				do {
					// First we have to fetch the existing record and then update.
					let existingRecord = try await fetchProfileRecord(.init(recordName: profile.id.uuidString))
					let fileManager = FileManager.default
					let tempDirectoryURL = fileManager.temporaryDirectory
					let fileURL = tempDirectoryURL.appendingPathComponent(UUID().uuidString)
					try! JSONEncoder().encode(profile).write(to: fileURL)
					existingRecord[.filenameProfileNotEncrypted]
					existingRecord[.content] = CKAsset(fileURL: fileURL)

					let record = try await CKContainer.default().privateCloudDatabase.save(existingRecord)
					try fileManager.removeItem(at: fileURL)
					return record
				} catch {
					let ckError = error as? CKError
					switch ckError?.code {
					case .unknownItem: // Item not in iCloud, create new
						do {
							let fileManager = FileManager.default
							let tempDirectoryURL = fileManager.temporaryDirectory
							let fileURL = tempDirectoryURL.appendingPathComponent(UUID().uuidString)
							try! JSONEncoder().encode(profile).write(to: fileURL)

							let record = CKRecord(recordType: .profile, recordID: .init(recordName: profile.id.uuidString))
							record[.content] = CKAsset(fileURL: fileURL)

							let savedRecord = try await CKContainer.default().privateCloudDatabase.save(record)
							try fileManager.removeItem(at: fileURL)
							return savedRecord
						} catch {
							throw error
						}
					default:
						break
					}
					throw error
				}
			},
			queryAllProfiles: {
				do {
					let records = try await CKContainer.default().privateCloudDatabase.records(
						matching: .init(
							recordType: .profile,
							predicate: .init(value: true)
						)
					)

					print("•• fetched \(records.matchResults.count)")

					for record in records.matchResults {
						try print("•• \(record.1.get())")
					}
					return try records.matchResults.compactMap { try? $0.1.get() }.map { record in
						guard record.recordType == .profile else {
							fatalError()
						}

						guard let asset = record[.content] as? CKAsset, let fileURL = asset.fileURL else {
							fatalError()
						}

						let fileManager = FileManager.default
						let data = try Data(contentsOf: fileURL)

						let profile = try! JSONDecoder().decode(Profile.self, from: data)

						print("•• got profile \(profile.id.uuidString)")

						return profile
					}
				} catch {
					throw error
				}
			},
			deleteProfile: { _ in
//				try await CKContainer.default().privateCloudDatabase.deleteRecord(withID: .init(recordName: id.uuidString))
			}
		)
	}

	func save(_ record: CKRecord) async throws {
		try await CKContainer.default().privateCloudDatabase.save(record)
	}
}
