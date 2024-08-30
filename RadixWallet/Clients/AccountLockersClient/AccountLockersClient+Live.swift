import Foundation

public typealias ClaimsPerAccount = [AccountAddress: [AccountLockerClaims]]

extension AccountLockersClient {
	public static let liveValue: Self = .live()

	public static func live() -> AccountLockersClient {
		@Dependency(\.authorizedDappsClient) var authorizedDappsClient
		@Dependency(\.accountsClient) var accountsClient
		@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient

		let accountLockersSubject = AsyncCurrentValueSubject<ClaimsPerAccount>([:])

		@Sendable
		func startMonitoring() async throws {
			let dappValues = await authorizedDappsClient.authorizedDappValues()
			let accountValues = await accountsClient.accountsOnCurrentNetwork()

			for try await (dapps, accounts) in combineLatest(dappValues, accountValues) {
				let dappsWithLockers = try await filterDappsWithAccountLockers(dapps)
				let lockersPerAccount = getLockersPerAccount(accounts: accounts, dapps: dappsWithLockers)
				let lockersStatePerAccount = try await getLockersStatePerAccount(lockersPerAccount: lockersPerAccount)

				var claimsPerAccount: [AccountAddress: [AccountLockerClaims]] = [:]
				for account in accounts {
					guard let lockerStates = lockersStatePerAccount[account.address] else { continue }
					var accountLockerClaims: [AccountLockerClaims] = []
					for lockerState in lockerStates.items {
						// TODO: Check from cache if the lockerState.lastTouchedAtStateVersion has changed from last time we checked

						let lockerContent = try await getLockerContent(lockerAddress: lockerState.lockerAddress, accountAddress: lockerState.accountAddress)
						let claims = lockerContent
							.filter(\.isValidClaim)
						accountLockerClaims.append(.init(
							lockerAddress: lockerState.lockerAddress,
							accountAddress: lockerState.accountAddress,
							lastTouchedAtStateVersion: lockerState.lastTouchedAtStateVersion,
							claims: claims
						))
					}
					claimsPerAccount[account.address] = accountLockerClaims
				}

				accountLockersSubject.send(claimsPerAccount)
				print("M- Result: \(claimsPerAccount)")
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
		func getLockerContent(lockerAddress: String, accountAddress: String) async throws -> [GatewayAPI.AccountLockerVaultCollectionItem] {
			try await gatewayAPIClient.getAccountLockerVaults(.init(lockerAddress: lockerAddress, accountAddress: accountAddress)).items
		}

		return .init(
			startMonitoring: startMonitoring,
			accountClaims: { account in
				accountLockersSubject.compactMap {
					$0[account]
				}
				.share()
				.eraseToAnyAsyncSequence()
			}
		)
	}

	private struct DappWithLockerAddress: Sendable, Hashable {
		let dapp: AuthorizedDapp
		let lockerAddress: String
	}
}

// MARK: - AccountLockerClaims
/// A struct holding the pending claims for a given locker address & account address.
public struct AccountLockerClaims: Sendable, Hashable {
	let lockerAddress: String
	let accountAddress: String // TODO: Consider removing it if not necessary
	let lastTouchedAtStateVersion: Int64
	let claims: [GatewayAPI.AccountLockerVaultCollectionItem]
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
		// TODO: Figure out why auto generated models don't have the amount/totalCount on them
		switch type {
		case .fungible:
			true // amount > 0
		case .nonFungible:
			true // totalCount > 0
		}
	}
}
