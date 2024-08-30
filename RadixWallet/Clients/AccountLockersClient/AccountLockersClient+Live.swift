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
				let dappsWithLockers = try await filterDappsWithAccountLockers(dapps)
				let lockersPerAccount = getLockersPerAccount(accounts: accounts, dapps: dappsWithLockers)
				print("M- Lockers per account: \(lockersPerAccount)")

				// Return [AccountAddress: [Claims]]
			}
		}

		@Sendable
		func filterDappsWithAccountLockers(_ dapps: AuthorizedDapps) async throws -> [DappWithLockerAddress] {
			// Filter dapps for which user doesn't want to see deposits
			let dappsWithDepositsVisible = dapps
				.filter(\.isDepositsVisible)
				.map(\.dappDefinitionAddress.asGeneral)

			// Get entity details from those dapps, to filter only those that actually have a primary locker.
			let dappsWithLocker = try await onLedgerEntitiesClient.getEntities(addresses: dappsWithDepositsVisible, metadataKeys: .dappMetadataKeys, cachingStrategy: .readFromLedgerSkipWrite)
				.compactMap(\.account)
				.compactMap { account -> (AccountAddress, String)? in
					guard let lockerAddress = account.details?.primaryLocker else {
						return nil
					}
					return (account.address, lockerAddress)
				}

			// Loop over the original input to only return those that actually have a primary locker
			return dapps.compactMap { dapp in
				guard let dappWithLocker = dappsWithLocker.first(where: { $0.0 == dapp.dappDefinitionAddress }) else {
					return nil
				}
				return DappWithLockerAddress(dapp: dapp, lockerAddress: dappWithLocker.1)
			}
		}

		@Sendable
		func getLockersPerAccount(accounts: Accounts, dapps: [DappWithLockerAddress]) -> [AccountAddress: [String]] {
			var result: [AccountAddress: [String]] = [:]
			for account in accounts {
				var lockerAddresses: [String] = []
				for dapp in dapps {
					let accountsInDapp = dapp.dapp.accountsInDapp
					if accountsInDapp.contains(account.address) {
						lockerAddresses.append(dapp.lockerAddress)
					}
				}
				if !lockerAddresses.isEmpty {
					result[account.address] = lockerAddresses
				}
			}

			return result
		}

		return .init(startMonitoring: startMonitoring)
	}

	private struct DappWithLockerAddress: Sendable, Hashable {
		let dapp: AuthorizedDapp
		let lockerAddress: String
	}
}

private extension AuthorizedDapp {
	var accountsInDapp: [AccountAddress] {
		referencesToAuthorizedPersonas
			.compactMap { $0.sharedAccounts?.ids }
			.flatMap { $0 }
	}
}
