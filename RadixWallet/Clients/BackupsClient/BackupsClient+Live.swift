
extension BackupsClient: DependencyKey {
	public typealias Value = BackupsClient

	public static let liveValue = Self.live()

	public static func live(
		profileStore: ProfileStore = .shared
	) -> Self {
		@Dependency(\.userDefaults) var userDefaults
		@Dependency(\.secureStorageClient) var secureStorageClient
		@Dependency(\.factorSourcesClient) var factorSourcesClient

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
				let containsP2PLinks = if let profileSnapshotData = try? secureStorageClient.loadProfileSnapshotData(header.id) {
					Profile.checkIfProfileJsonContainsLegacyP2PLinks(contents: profileSnapshotData)
				} else {
					false
				}
				let profileSnapshot = try secureStorageClient.loadProfileSnapshot(header.id)

				return (profileSnapshot, containsP2PLinks)
			},
			importProfileSnapshot: { snapshot, factorSourceIDs, containsP2PLinks in
				do {
					try await profileStore.importProfileSnapshot(snapshot)
					userDefaults.setShowRelinkConnectorsAfterProfileRestore(containsP2PLinks)
				} catch {
					// Revert the saved mnemonic
					for factorSourceID in factorSourceIDs {
						try? secureStorageClient.deleteMnemonicByFactorSourceID(factorSourceID)
					}
					throw error
				}
			},
			didExportProfileSnapshot: { profile in
				try userDefaults.setLastManualBackup(of: profile)
			},
			loadDeviceID: {
				try? secureStorageClient.loadDeviceInfo()?.id
			}
		)
	}
}
