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

	/// Subscribe to portfolio changes for a given account address
	public var portfolioForAccount: PortfolioForAccount

	public var portfoliosUpdates: PortfoliosUpdates

	/// Currently loaded portfolios
	public var portfolios: Portfolios
}

extension AccountPortfoliosClient {
	public typealias FetchAccountPortfolio = @Sendable (_ address: AccountAddress, _ forceResfresh: Bool) async throws -> OnLedgerEntity.Account
	public typealias FetchAccountPortfolios = @Sendable (_ addresses: [AccountAddress], _ forceResfresh: Bool) async throws -> [OnLedgerEntity.Account]
	public typealias PortfolioForAccount = @Sendable (_ address: AccountAddress) async -> AnyAsyncSequence<OnLedgerEntity.Account>
	public typealias PortfoliosUpdates = @Sendable () async -> AnyAsyncSequence<[OnLedgerEntity.Account]>
	public typealias Portfolios = @Sendable () -> [OnLedgerEntity.Account]
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

			let changedAccounts: [Profile.Network.Account.EntityAddress]?
			let resourceAddressesToRefresh: [Address]?
			do {
				let manifest = intent.manifest()

				let involvedAccounts = try await transactionClient.myInvolvedEntities(manifest)
				changedAccounts = involvedAccounts.accountsDepositedInto
					.union(involvedAccounts.accountsWithdrawnFrom)
					.map(\.address)

				let involvedAddresses = manifest.extractAddresses()
				/// Refresh the resources if an operation on resource pool is involved,
				/// reason being that contributing or withdrawing from a resource pool modifies the totalSupply
				if involvedAddresses.contains(where: \.key.isResourcePool) {
					/// A little bit too aggressive, as any other resource will also be refreshed.
					/// But at this stage we cannot determine(without making additional calls) the pool unit related fungible resource
					resourceAddressesToRefresh = involvedAddresses
						.filter { $0.key == .globalFungibleResourceManager || $0.key.isResourcePool }
						.values
						.flatMap(identity)
						.compactMap { try? $0.asSpecific() }
				} else {
					resourceAddressesToRefresh = nil
				}
			} catch {
				loggerGlobal.warning("Could get transactionClient.myInvolvedEntities: \(error.localizedDescription)")
				changedAccounts = nil
				resourceAddressesToRefresh = nil
			}

			if let resourceAddressesToRefresh {
				for item in resourceAddressesToRefresh {
					cacheClient.removeFile(.onLedgerEntity(.resource(item.asGeneral)))
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
