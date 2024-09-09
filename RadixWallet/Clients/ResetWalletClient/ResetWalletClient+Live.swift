import ComposableArchitecture

extension ResetWalletClient: DependencyKey {
	public static let liveValue: Self = {
		@Dependency(\.errorQueue) var errorQueue
		@Dependency(\.appPreferencesClient) var appPreferencesClient
		@Dependency(\.cacheClient) var cacheClient
		@Dependency(\.radixConnectClient) var radixConnectClient
		@Dependency(\.userDefaults) var userDefaults
		@Dependency(\.appEventsClient) var appEventsClient

		return Self(
			resetWallet: {
				do {
					try await appPreferencesClient.deleteProfileAndFactorSources(true)
					cacheClient.removeAll()
					await radixConnectClient.disconnectAll()
					userDefaults.removeAll()
					appEventsClient.handleEvent(.walletDidReset)
				} catch {
					loggerGlobal.error("Failed to delete profile: \(error)")
					errorQueue.schedule(error)
				}
			}
		)
	}()
}
