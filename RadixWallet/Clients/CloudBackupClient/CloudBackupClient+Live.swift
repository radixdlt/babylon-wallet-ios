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

	private static let container = CKContainer(identifier: "iCloud.com.radixpublishing.radixwallet.ios.dev.cloudBackup")

	public static func live(
		profileStore: ProfileStore = .shared
	) -> CloudBackupClient {
		func fetchProfileRecord(_ id: CKRecord.ID) async throws -> CKRecord {
			try await container.privateCloudDatabase.record(for: id)
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
//			let savedRecord = try await container.privateCloudDatabase.save(record)
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
				print("•• uploadProfile")

				do {
					// First we have to fetch the existing record and then update.
					let existingRecord = try await fetchProfileRecord(.init(recordName: profile.id.uuidString))

					print("•• record found already")

					let fileManager = FileManager.default
					let tempDirectoryURL = fileManager.temporaryDirectory
					let fileURL = tempDirectoryURL.appendingPathComponent(UUID().uuidString)
					try! JSONEncoder().encode(profile).write(to: fileURL)
					existingRecord[.content] = CKAsset(fileURL: fileURL)

					existingRecord["Name"] = profile.id.uuidString

					let record = try await container.privateCloudDatabase.save(existingRecord)
					try fileManager.removeItem(at: fileURL)
					return record
				} catch {
					let ckError = error as? CKError
					switch ckError?.code {
					case .unknownItem: // Item not in iCloud, create new
						print("•• record not found previously")
						do {
							let fileManager = FileManager.default
							let tempDirectoryURL = fileManager.temporaryDirectory
							let fileURL = tempDirectoryURL.appendingPathComponent(UUID().uuidString)
							try! JSONEncoder().encode(profile).write(to: fileURL)

							let record = CKRecord(recordType: .profile, recordID: .init(recordName: profile.id.uuidString))
							record[.content] = CKAsset(fileURL: fileURL)
							record["Name"] = "NEW:" + profile.id.uuidString

							let savedRecord = try await container.privateCloudDatabase.save(record)
							try fileManager.removeItem(at: fileURL)
							return savedRecord
						} catch {
							print("•• failed to save: \(error)")
							throw error
						}
					default:
						print("•• other error: \(error)")
					}
					throw error
				}
			},
			queryAllProfiles: {
				do {
					let records = try await container.privateCloudDatabase.records(
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

						let name = (record["Name"] as? String) ?? "--"
						print("•• got profile \(name): \(profile)")

						return profile
					}
				} catch {
					print("•• can't get profiles: \(error)")
					throw error
				}
			},
			deleteProfile: { _ in
//				try await container.privateCloudDatabase.deleteRecord(withID: .init(recordName: id.uuidString))
			}
		)
	}
}
