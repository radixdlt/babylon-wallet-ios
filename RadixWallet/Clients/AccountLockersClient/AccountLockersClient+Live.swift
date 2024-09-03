import Foundation

public typealias ClaimsPerAccount = [AccountAddress: [AccountLockerClaimDetails]]

extension AccountLockersClient {
	public static let liveValue: Self = .live()

	public static func live() -> AccountLockersClient {
		@Dependency(\.authorizedDappsClient) var authorizedDappsClient
		@Dependency(\.accountsClient) var accountsClient
		@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient
		@Dependency(\.cacheClient) var cacheClient

		let claimsPerAccountSubject = AsyncCurrentValueSubject<ClaimsPerAccount>([:])

		@Sendable
		func startMonitoring() async throws {
			// We will check the account locker claims on different conditions:

			// Trigger any time the authorized dapps changes (at any level)
			let dappValues = await authorizedDappsClient.authorizedDappValues()

			// Trigger any time accounts are added/removed.
			let accountValues = await accountsClient.accountsOnCurrentNetwork().removeDuplicates(by: { $0.map(\.id) == $1.map(\.id) })

			// Trigger every 5 minutes
			let timer = AsyncTimerSequence(every: .minutes(5))

			for try await (dapps, accounts, _) in combineLatest(dappValues, accountValues, timer) {
				do {
					try await checkClaims(dapps: dapps, accounts: accounts)
				} catch {
					loggerGlobal.error("Failed to check account locker claims \(error)")
				}
			}
		}

		@Sendable
		func checkClaims(dapps: AuthorizedDapps, accounts: Accounts) async throws {
			// Fetch dapp & account lockers state
			let dappsWithLockers = try await filterDappsWithAccountLockers(dapps)
			let lockersPerAccount = getLockersPerAccount(accounts: accounts, dapps: dappsWithLockers)
			let lockersStatePerAccount = try await getLockersStatePerAccount(lockersPerAccount: lockersPerAccount)

			var claimsPerAccount: ClaimsPerAccount = [:]

			// Loop over each account to determine its claims
			for account in accounts {
				guard let lockerStates = lockersStatePerAccount[account.address] else {
					// If there are no lockers for the given account, set an empty list for it
					// This is necessary so that if such account used to have, but doesn't have any more, we emit an update
					// for such account removing the old list of claims.
					claimsPerAccount[account.address] = []
					continue
				}
				var accountDetails: [AccountLockerClaimDetails] = []

				// Loop over each locker associated to this account
				for lockerState in lockerStates.items {
					let accountAddress = try AccountAddress(validatingAddress: lockerState.accountAddress)
					let lockerAddress = try LockerAddress(validatingAddress: lockerState.lockerAddress)

					let cached = getCachedVersionIfValid(
						accountAddress: accountAddress,
						lockerAddress: lockerAddress,
						lastTouchedAtStateVersion: lockerState.lastTouchedAtStateVersion
					)

					if let cached {
						// The cached claim information is valid.
						accountDetails.append(cached)
					} else {
						// The cache is outdated or doesn't exist, so we will fetch info from Gateway
						let lockerContent = try await getLockerContent(lockerAddress: lockerAddress, accountAddress: accountAddress)
						let claims: [AccountLockerClaimDetails.Claim] = lockerContent
							.filter(\.isValidClaim)
							.compactMap { try? .init($0) }

						guard let dapp = dappsWithLockers.first(where: { $0.lockerAddress == lockerAddress.address })?.dapp else {
							assertionFailure("Programmer error: there should be a dapp for the given locker")
							continue
						}

						let details = AccountLockerClaimDetails(
							lockerAddress: lockerAddress,
							accountAddress: accountAddress,
							dappDefinitionAddress: dapp.dappDefinitionAddress,
							dappName: dapp.displayName,
							lastTouchedAtStateVersion: lockerState.lastTouchedAtStateVersion,
							claims: claims
						)

						// Cache the result and append to list
						cacheClient.save(details, .accountLockerClaimDetails(accountAddress, lockerAddress))
						accountDetails.append(details)
					}
				}

				// Set the details for the given account, filtering those who have no claims.
				claimsPerAccount[account.address] = accountDetails.filter(not(\.claims.isEmpty))
			}

			// Emit a new result
			claimsPerAccountSubject.send(claimsPerAccount)
		}

		@Sendable
		func filterDappsWithAccountLockers(_ dapps: AuthorizedDapps) async throws -> [DappWithLockerAddress] {
			// Filter dapps for which user doesn't want to see deposits
			let dappsWithDepositsVisible = dapps
				.filter(\.isDepositsVisible)
				.map(\.dappDefinitionAddress.asGeneral)

			// Get entity details from those dapps, to filter only those that actually have a primary locker.
			let dappsWithLocker = try await onLedgerEntitiesClient
				.getEntities(dappsWithDepositsVisible, .init(dappTwoWayLinks: true), nil, .useCache, false)
				.compactMap { entity -> (AccountAddress, String)? in
					guard
						let account = entity.account,
						let lockerAddress = account.details?.primaryLocker
					else {
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
				let lockerAddresses = dapps
					.filter { $0.dapp.accountsInDapp.contains(account.address) }
					.map(\.lockerAddress)
				if !lockerAddresses.isEmpty {
					result[account.address] = lockerAddresses
				}
			}

			return result
		}

		typealias LockersStatePerAccount = [AccountAddress: GatewayAPI.StateAccountLockersTouchedAtResponse]

		@Sendable
		func getLockersStatePerAccount(lockersPerAccount: [AccountAddress: [String]]) async throws -> LockersStatePerAccount {
			let result = try await lockersPerAccount.parallelMap { accountAddress, lockers in
				let accountLockers = lockers.map {
					GatewayAPI.AccountLockerAddress(lockerAddress: $0, accountAddress: accountAddress.address)
				}
				let response = try await gatewayAPIClient.getAccountLockerTouchedAt(.init(accountLockers: accountLockers))
				return (accountAddress, response)
			}
			return Dictionary(uniqueKeysWithValues: result.map { ($0.0, $0.1) })
		}

		@Sendable
		func getCachedVersionIfValid(accountAddress: AccountAddress, lockerAddress: LockerAddress, lastTouchedAtStateVersion: AtStateVersion) -> AccountLockerClaimDetails? {
			let entry = CacheClient.Entry.accountLockerClaimDetails(accountAddress, lockerAddress)
			guard
				let cached = try? cacheClient.load(AccountLockerClaimDetails.self, entry) as? AccountLockerClaimDetails,
				cached.lastTouchedAtStateVersion == lastTouchedAtStateVersion
			else {
				return nil
			}
			return cached
		}

		@Sendable
		func getLockerContent(lockerAddress: LockerAddress, accountAddress: AccountAddress) async throws -> [GatewayAPI.AccountLockerVaultCollectionItem] {
			try await gatewayAPIClient.fetchAllPaginatedItems(cursor: nil, gatewayAPIClient.getAccountLockerVaultsPage(lockerAddress: lockerAddress, accountAddress: accountAddress))
		}

		let dappsWithClaims: DappsWithClaims = {
			claimsPerAccountSubject
				.map { claimsPerAccount in
					let addresses = claimsPerAccount.values.flatMap { claims in
						claims.map(\.dappDefinitionAddress)
					}
					return Array(Set(addresses))
				}
				.share()
				.eraseToAnyAsyncSequence()
		}

		return .init(
			startMonitoring: startMonitoring,
			accountClaims: { account in
				claimsPerAccountSubject.compactMap {
					$0[account]
				}
				.share()
				.eraseToAnyAsyncSequence()
			},
			dappsWithClaims: dappsWithClaims
		)
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

private extension GatewayAPI.AccountLockerVaultCollectionItem {
	var isValidClaim: Bool {
		switch self {
		case let .fungible(fungible):
			Int(fungible.amount) ?? 0 > 0
		case let .nonFungible(nonFungible):
			nonFungible.totalCount > 0
		}
	}
}
