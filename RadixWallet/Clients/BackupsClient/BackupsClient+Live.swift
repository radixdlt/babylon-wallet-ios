
extension BackupsClient: DependencyKey {
	public static let liveValue = Self.live()

	public static func live(
		profileStore: ProfileStore = .shared
	) -> Self {
		@Dependency(\.userDefaults) var userDefaults
		@Dependency(\.secureStorageClient) var secureStorageClient

		return Self(
			snapshotOfProfileForExport: {
				await profileStore.profile
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
