
extension TransportProfileClient: DependencyKey {
	public static let liveValue = Self.live()

	public static func live(
		profileStore: ProfileStore = .shared
	) -> Self {
		@Dependency(\.userDefaults) var userDefaults
		@Dependency(\.secureStorageClient) var secureStorageClient

		return Self(
			importProfile: { profile, factorSourceIDs, containsP2PLinks in
				do {
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
