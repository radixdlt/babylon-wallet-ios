// MARK: - AccountPortfoliosClient
public struct AccountPortfoliosClient: Sendable {
	/// Fetches the account portfolios for the given addresses.
	///
	/// Will return the portfolios after fetch, as well will notify any subscribes through `portfolioForAccount`
	public var fetchAccountPortfolios: FetchAccountPortfolios

	/// Fetches the account portfolio for the given address.
	///
	/// Will return the portfolio after fetch, as well will notify any subscribes through `portfolioForAccount`
	public var fetchAccountPortfolio: FetchAccountPortfolio

	public var portfolioUpdates: PortfolioUpdates

	/// Subscribe to portfolio changes for a given account address
	public var portfolioForAccount: PortfolioForAccount

	/// Currently loaded portfolios
	public var portfolios: Portfolios
}

extension AccountPortfoliosClient {
	public typealias FetchAccountPortfolio = @Sendable (_ address: AccountAddress, _ forceResfresh: Bool) async throws -> AccountPortfolio
	public typealias FetchAccountPortfolios = @Sendable (_ addresses: [AccountAddress], _ forceResfresh: Bool) async throws -> [AccountPortfolio]
	public typealias PortfolioForAccount = @Sendable (_ address: AccountAddress) async -> AnyAsyncSequence<AccountPortfolio>

	public typealias PortfolioUpdates = @Sendable () -> AnyAsyncSequence<Loadable<[AccountPortfolio]>>
	public typealias Portfolios = @Sendable () -> [AccountPortfolio]
}

extension DependencyValues {
	public var accountPortfoliosClient: AccountPortfoliosClient {
		get { self[AccountPortfoliosClient.self] }
		set { self[AccountPortfoliosClient.self] = newValue }
	}
}

extension AccountPortfoliosClient {
	/// Update the portfolio after a given transaction was successfull
	public func updateAfterCommittedTransaction(_ intent: TransactionIntent) {
		Task.detached {
			@Dependency(\.transactionClient) var transactionClient
			@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient
			@Dependency(\.cacheClient) var cacheClient

			let changedAccounts: [Sargon.Account.EntityAddress]?
			let poolAddressesToRefresh: [PoolAddress]?
			do {
				let manifest = intent.manifest

				let involvedAccounts = try await transactionClient.myInvolvedEntities(manifest)
				changedAccounts = involvedAccounts.accountsDepositedInto
					.union(involvedAccounts.accountsWithdrawnFrom)
					.map(\.address)

				let involvedPoolAddresses = manifest.involvedPoolAddresses
				/// Refresh the resources if an operation on resource pool is involved,
				/// reason being that contributing or withdrawing from a resource pool modifies the totalSupply
				if !involvedPoolAddresses.isEmpty {
					/// A little bit too aggressive, as any other resource will also be refreshed.
					/// But at this stage we cannot determine(without making additional calls) the pool unit related fungible resource
					poolAddressesToRefresh = involvedPoolAddresses
				} else {
					poolAddressesToRefresh = nil
				}
			} catch {
				loggerGlobal.warning("Could get transactionClient.myInvolvedEntities: \(error.localizedDescription)")
				changedAccounts = nil
				poolAddressesToRefresh = nil
			}

			if let poolAddressesToRefresh {
				for item in poolAddressesToRefresh {
					cacheClient.removeFile(.onLedgerEntity(.address(.pool(item))))
				}
			}

			if let changedAccounts {
				// FIXME: Ideally we should only have to call the cacheClient here
				// cacheClient.clearCacheForAccounts(Set(changedAccounts))
				_ = try await fetchAccountPortfolios(changedAccounts, true)
			}
		}
	}
}
