import ComposableArchitecture

extension ResetWalletClient: DependencyKey {
	public static let liveValue: Self = {
		let walletDidResetSubject = AsyncPassthroughSubject<Void>()

		@Dependency(\.cacheClient) var cacheClient
		@Dependency(\.radixConnectClient) var radixConnectClient
		@Dependency(\.userDefaults) var userDefaults

		return Self(
			resetWallet: {
				cacheClient.removeAll()
				await radixConnectClient.disconnectAll()
				userDefaults.removeAll()
				walletDidResetSubject.send(())
			},
			walletDidReset: {
				walletDidResetSubject.eraseToAnyAsyncSequence()
			}
		)
	}()
}
