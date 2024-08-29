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
				try await filterDappsWithAccountLockers(dapps)
			}
		}

		@Sendable
		func filterDappsWithAccountLockers(_ dapps: AuthorizedDapps) async throws -> AuthorizedDapps {
			let entities = try await onLedgerEntitiesClient.getEntities(addresses: dapps.map(\.dAppDefinitionAddress.asGeneral), metadataKeys: .dappMetadataKeys).compactMap(\.account)

			return dapps
		}

		return .init(startMonitoring: startMonitoring)
	}
}
