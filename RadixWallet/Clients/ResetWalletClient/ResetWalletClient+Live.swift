import ComposableArchitecture

extension ResetWalletClient: DependencyKey {
	public static let liveValue: Self = {
		let walletDidResetSubject = AsyncPassthroughSubject<Void>()

		@Dependency(\.errorQueue) var errorQueue
		@Dependency(\.appPreferencesClient) var appPreferencesClient
		@Dependency(\.cacheClient) var cacheClient
		@Dependency(\.radixConnectClient) var radixConnectClient
		@Dependency(\.userDefaults) var userDefaults

		return Self(
			resetWallet: {
				do {
					// TODO: Is this the best order?
					try await appPreferencesClient.deleteProfileAndFactorSources(true)
					cacheClient.removeAll()
					await radixConnectClient.disconnectAll()
					userDefaults.removeAll()
					walletDidResetSubject.send(())
				} catch {
					loggerGlobal.error("Failed to delete profile: \(error)")
					errorQueue.schedule(error)
				}
			},
			walletDidReset: {
				walletDidResetSubject.eraseToAnyAsyncSequence()
			}
		)
	}()
}
