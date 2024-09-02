import Foundation

public typealias ClaimsPerAccount = [AccountAddress: [AccountLockerClaims]]

extension AccountLockersClient {
	public static let liveValue: Self = .live()

	public static func live() -> AccountLockersClient {
		@Dependency(\.authorizedDappsClient) var authorizedDappsClient
		@Dependency(\.accountsClient) var accountsClient
		@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient
		@Dependency(\.cacheClient) var cacheClient

		let claimsPerAccountSubject = AsyncCurrentValueSubject<ClaimsPerAccount>([:])

		let timerInterval: DispatchTimeInterval = .seconds(600) // 10 minutes

		@Sendable
		func startMonitoring() async throws {
			let dappValues = await authorizedDappsClient.authorizedDappValues()
			let accountValues = await accountsClient.accountsOnCurrentNetwork()
			let timer = AsyncTimerSequence(every: timerInterval)

			for try await (dapps, accounts, _) in combineLatest(dappValues, accountValues, timer) {
				// Fetch dapp & account lockers state
				let dappsWithLockers = try await filterDappsWithAccountLockers(dapps)
				let lockersPerAccount = getLockersPerAccount(accounts: accounts, dapps: dappsWithLockers)
				let lockersStatePerAccount = try await getLockersStatePerAccount(lockersPerAccount: lockersPerAccount)

				var claimsPerAccount: ClaimsPerAccount = [:]

				// Loop over each account to determine its claims
				for account in accounts {
					guard let lockerStates = lockersStatePerAccount[account.address] else { continue }
					var accountLockerClaims: [AccountLockerClaims] = []

					// Loop over each locker associated to this account
					for lockerState in lockerStates.items {
						if let cached = getCachedVersionIfValid(lockerState: lockerState) {
							// The cached claim information is valid.
							accountLockerClaims.append(cached)

						} else {
							// The cache is outdated or doesn't exist, so we will fetch its details from Gateway
							let lockerAddress = lockerState.lockerAddress
							let accountAddress = lockerState.accountAddress
							let lockerContent = try await getLockerContent(lockerAddress: lockerAddress, accountAddress: accountAddress)
							let claims = lockerContent.filter(\.isValidClaim)

							guard let dapp = dappsWithLockers.first(where: { $0.lockerAddress == lockerAddress })?.dapp else {
								fatalError("Programmer error: there should be a dapp for the given locker")
							}

							let accountLockerClaim = AccountLockerClaims(
								lockerAddress: lockerAddress,
								accountAddress: accountAddress,
								dappDefinitionAddress: dapp.dappDefinitionAddress.address,
								dappName: dapp.displayName,
								lastTouchedAtStateVersion: lockerState.lastTouchedAtStateVersion,
								claims: claims
							)

							// Cache the result and append to list
							cacheClient.save(accountLockerClaim, .accountLockerClaims(accountAddress: accountAddress, lockerAddress: lockerAddress))
							accountLockerClaims.append(accountLockerClaim)
						}
					}

					// Set the claims for the given account, filtering those that are empty.
					claimsPerAccount[account.address] = accountLockerClaims.filter(not(\.claims.isEmpty))
				}

				// Emit a new result
				claimsPerAccountSubject.send(claimsPerAccount)
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
		func getCachedVersionIfValid(lockerState: GatewayAPI.StateAccountLockersTouchedAtResponseItem) -> AccountLockerClaims? {
			let entry = CacheClient.Entry.accountLockerClaims(accountAddress: lockerState.accountAddress, lockerAddress: lockerState.lockerAddress)
			guard
				let cached = try? cacheClient.load(AccountLockerClaims.self, entry) as? AccountLockerClaims,
				cached.lastTouchedAtStateVersion == lockerState.lastTouchedAtStateVersion
			else {
				return nil
			}
			return cached
		}

		@Sendable
		func getLockerContent(lockerAddress: String, accountAddress: String) async throws -> [GatewayAPI.AccountLockerVaultCollectionItem] {
			try await gatewayAPIClient.getAccountLockerVaults(.init(lockerAddress: lockerAddress, accountAddress: accountAddress)).items
		}

		let dappsWithClaims: @Sendable () async -> AnyAsyncSequence<[String]> = {
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
