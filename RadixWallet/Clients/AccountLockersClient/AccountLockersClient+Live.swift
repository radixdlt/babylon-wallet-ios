import Foundation

extension AccountLockersClient {
	public static let liveValue: Self = .live()

	public static func live() -> AccountLockersClient {
		@Dependency(\.authorizedDappsClient) var authorizedDappsClient
		@Dependency(\.accountsClient) var accountsClient
		@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient

		@Sendable
		func startMonitoring() async throws {
			let dappValues = await authorizedDappsClient.authorizedDappValues()
			let accountValues = await accountsClient.accountsOnCurrentNetwork()

			for try await (dapps, accounts) in combineLatest(dappValues, accountValues) {
				_ = try await filterDappsWithAccountLockers(dapps)
			}
		}

		@Sendable
		func filterDappsWithAccountLockers(_ dapps: AuthorizedDapps) async throws -> AuthorizedDapps {
			let dappsWithPrimaryLocker = try await onLedgerEntitiesClient.getEntities(addresses: dapps.map(\.dAppDefinitionAddress.asGeneral), metadataKeys: .dappMetadataKeys, cachingStrategy: .readFromLedgerSkipWrite)
				.compactMap(\.account)
				.filter { account in
					account.details?.primaryLocker != nil
				}
				.map(\.address)

			let result = dapps.filter { dapp in
				dappsWithPrimaryLocker.contains(dapp.dappDefinitionAddress)
			}

			return result
		}

		return .init(startMonitoring: startMonitoring)
	}
}
