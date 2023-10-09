import CacheClient
import ClientPrelude
import EngineKit
import GatewayAPI
import OnLedgerEntitiesClient
import SharedModels

// MARK: - AccountPortfoliosClient + DependencyKey
extension AccountPortfoliosClient: DependencyKey {
	/// Internal state that holds all loaded portfolios.
	actor State {
		let portfoliosSubject: AsyncCurrentValueSubject<[AccountAddress: OnLedgerEntity.Account]> = .init([:])

		func setAccountPortfolio(_ portfolio: OnLedgerEntity.Account) {
			portfoliosSubject.value.updateValue(portfolio, forKey: portfolio.address)
		}

		func setAccountPortfolios(_ portfolios: [OnLedgerEntity.Account]) {
			portfolios.forEach(setAccountPortfolio)
		}

		func portfolioForAccount(_ address: AccountAddress) -> AnyAsyncSequence<OnLedgerEntity.Account> {
			portfoliosSubject.compactMap { $0[address] }.eraseToAnyAsyncSequence()
		}
	}

	public static let liveValue: AccountPortfoliosClient = {
		let state = State()

		@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient
		@Dependency(\.cacheClient) var cacheClient

		return AccountPortfoliosClient(
			fetchAccountPortfolios: { accountAddresses, forceRefresh in
				if forceRefresh {
					accountAddresses.forEach {
						cacheClient.removeFolder(.onLedgerEntity(.account($0.asGeneral)))
					}
				}

				let accounts = try await onLedgerEntitiesClient.getAccounts(accountAddresses)

				// Update the current account portfolios
				await state.setAccountPortfolios(accounts)

				return accounts
			},
			fetchAccountPortfolio: { accountAddress, _ in
				guard let portfolio = try await onLedgerEntitiesClient.getAccounts([accountAddress]).first else {
					fatalError()
				}

				await state.setAccountPortfolio(portfolio)

				return portfolio
			},
			portfolioForAccount: { address in
				await state.portfolioForAccount(address)
			},
			portfolios: { state.portfoliosSubject.value.map(\.value) }
		)
	}()
}
