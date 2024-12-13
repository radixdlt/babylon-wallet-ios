
extension TransportProfileClient: DependencyKey {
	static let liveValue = Self.live()

	static func live(
		profileStore: ProfileStore = .shared
	) -> Self {
		@Dependency(\.userDefaults) var userDefaults
		@Dependency(\.secureStorageClient) var secureStorageClient
		@Dependency(\.cloudBackupClient) var cloudBackupClient

		return Self(
			importProfile: { profile, factorSourceIDs, skippedMainBdfs, containsP2PLinks in
				do {
					try await profileStore.importProfile(profile, skippedMainBdfs: skippedMainBdfs)
					let profile = await profileStore.profile()
					if profile.appPreferences.security.isCloudProfileSyncEnabled {
						try? await cloudBackupClient.claimProfileOnICloud(profile)
					}
					userDefaults.setShowRelinkConnectorsAfterProfileRestore(containsP2PLinks)
				} catch {
					// Revert the saved mnemonic
					for factorSourceID in factorSourceIDs {
						try? secureStorageClient.deleteMnemonicByFactorSourceID(factorSourceID)
					}
					throw error
				}
			},
			profileForExport: {
				await profileStore.profile()
			},
			didExportProfile: { profile in
				try userDefaults.setLastManualBackup(of: profile)
			}
		)
	}
}
