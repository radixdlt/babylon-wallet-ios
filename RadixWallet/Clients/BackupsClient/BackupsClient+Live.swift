
extension BackupsClient: DependencyKey {
	public typealias Value = BackupsClient

	public static let liveValue = Self.live()

	public static func live(
		profileStore: ProfileStore = .shared
	) -> Self {
		@Dependency(\.userDefaults) var userDefaults
		@Dependency(\.secureStorageClient) var secureStorageClient
		@Dependency(\.factorSourcesClient) var factorSourcesClient

		@Sendable
		func importFor(
			factorSourceIDs: Set<FactorSourceIDFromHash>,
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
				await profileStore.profile
			},
			loadProfileBackups: { () -> Profile.HeaderList? in
				do {
					let headers = try secureStorageClient.loadProfileHeaderList()
					guard let headers else {
						return nil
					}
					// filter out header for which the related profile is not present in the keychain:
					var filteredHeaders = [Profile.Header]()
					for header in headers {
						guard
							let snapshot = try? secureStorageClient.loadProfileSnapshot(header.id),
							// A profile will be empty (no network) if you start app and go to RESTORE.
							// We will delete this empty profile in ProfileStore once user finished import.
							!snapshot.networks.isEmpty
						else {
							continue
						}
						filteredHeaders.append(header)
					}
					guard !filteredHeaders.isEmpty else {
						return nil
					}

					return .init(rawValue: filteredHeaders.asIdentified())
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
			didExportProfileSnapshot: { profile in
				print("•• didExportProfileSnapshot")
				try userDefaults.setLastManualBackup(of: profile)
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
