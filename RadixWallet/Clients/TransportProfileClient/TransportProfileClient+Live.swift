
extension TransportProfileClient: DependencyKey {
	public static let liveValue = Self.live()

	public static func live(
		profileStore: ProfileStore = .shared
	) -> Self {
		@Dependency(\.userDefaults) var userDefaults
		@Dependency(\.secureStorageClient) var secureStorageClient
		@Dependency(\.cloudBackupClient) var cloudBackupClient

		return Self(
			importProfile: { profile, factorSourceIDs, containsP2PLinks in
				do {
					var profile = profile
					await profileStore.claimOwnership(of: &profile)
					if profile.appSettings.security.isCloudProfileSyncEnabled {
						try await cloudBackupClient.claimProfileOnICloud(profile)
					}
					try await profileStore.importProfile(profile)
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
				await profileStore.profile
			},
			didExportProfile: { profile in
				try userDefaults.setLastManualBackup(of: profile)
			}
		)
	}
}
