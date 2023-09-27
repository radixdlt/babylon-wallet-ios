import BackupsClient
import ClientPrelude
import FactorSourcesClient
import ProfileStore

extension BackupsClient: DependencyKey {
	public typealias Value = BackupsClient

	public static let liveValue = Self.live()

	public static func live(
		profileStore getProfileStore: @escaping @Sendable () async -> ProfileStore = { await .shared }
	) -> Self {
		@Dependency(\.userDefaultsClient) var userDefaultsClient
		@Dependency(\.secureStorageClient) var secureStorageClient
		@Dependency(\.factorSourcesClient) var factorSourcesClient

		@Sendable
		func importFor(
			factorSourceIDs: Set<FactorSourceID.FromHash>,
			operation: () async throws -> Void
		) async throws {
			do {
				try await operation()
			} catch {
				// revert the saved mnemonic
				for factorSourceID in factorSourceIDs {
					try? await secureStorageClient.deleteMnemonicByFactorSourceID(factorSourceID)
				}
				throw error
			}
		}

		return Self(
			snapshotOfProfileForExport: {
				let profileStore = await getProfileStore()
				let profileOutcome = await profileStore.getLoadProfileOutcome()
				switch profileOutcome {
				case .existingProfile:
					return await profileStore.profile.snapshot()
				default:
					loggerGlobal.error("Expected to find persisted profile in ProfileStore, but was \(profileOutcome)")
					struct NoPersistedProfile: Error {}
					throw NoPersistedProfile()
				}
			},
			loadProfileBackups: { () -> ProfileSnapshot.HeaderList? in
				do {
					let headers = try await secureStorageClient.loadProfileHeaderList()
					guard let headers else {
						return nil
					}
					// filter out header for which the related profile is not present in the keychain:
					var filteredHeaders = [ProfileSnapshot.Header]()
					for header in headers {
						guard let _ = try? await secureStorageClient.loadProfileSnapshotData(header.id) else {
							continue
						}
						filteredHeaders.append(header)
					}
					guard !filteredHeaders.isEmpty else {
						return nil
					}
					return .init(rawValue: .init(uniqueElements: filteredHeaders))
				} catch {
					assertionFailure("Corrupt Profile headers")
					loggerGlobal.critical("Corrupt Profile header: \(error.legibleLocalizedDescription)")
					// Corrupt Profile Headers, delete
					_ = try? await secureStorageClient.deleteProfileHeaderList()
					return nil
				}
			},
			lookupProfileSnapshotByHeader: { header in
				try await secureStorageClient.loadProfileSnapshot(header.id)
			},
			importProfileSnapshot: { snapshot, factorSourceIDs in
				try await importFor(factorSourceIDs: factorSourceIDs) {
					try await getProfileStore().importProfileSnapshot(snapshot)
				}
			},
			importCloudProfile: { header, factorSourceIDs in
				try await importFor(factorSourceIDs: factorSourceIDs) {
					try await getProfileStore().importCloudProfileSnapshot(header)
				}
			},
			loadDeviceID: {
				try? await secureStorageClient.loadDeviceIdentifier()
			}
		)
	}
}
