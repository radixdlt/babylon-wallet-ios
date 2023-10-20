
extension BackupsClient: DependencyKey {
	public typealias Value = BackupsClient

	public static let liveValue = Self.live()

	public static func live(
		profileStore: ProfileStore = .shared
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
					try? secureStorageClient.deleteMnemonicByFactorSourceID(factorSourceID)
				}
				throw error
			}
		}

		return Self(
			snapshotOfProfileForExport: {
				await profileStore.profile.snapshot()
			},
			loadProfileBackups: { () -> ProfileSnapshot.HeaderList? in
				do {
					let headers = try secureStorageClient.loadProfileHeaderList()
					guard let headers else {
						return nil
					}
					// filter out header for which the related profile is not present in the keychain:
					var filteredHeaders = [ProfileSnapshot.Header]()
					for header in headers {
						guard let _ = try? secureStorageClient.loadProfileSnapshotData(header.id) else {
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
					_ = try? secureStorageClient.deleteProfileHeaderList()
					return nil
				}
			},
			lookupProfileSnapshotByHeader: { header in
				try secureStorageClient.loadProfileSnapshot(header.id)
			},
			importProfileSnapshot: { snapshot, factorSourceIDs in
				try await importFor(factorSourceIDs: factorSourceIDs) {
					try await profileStore.importProfileSnapshot(snapshot)
				}
			},
			importCloudProfile: { header, factorSourceIDs in
				try await importFor(factorSourceIDs: factorSourceIDs) {
					try await profileStore.importCloudProfileSnapshot(header)
				}
			},
			loadDeviceID: {
				try? secureStorageClient.loadDeviceInfo()?.id
			}
		)
	}
}
