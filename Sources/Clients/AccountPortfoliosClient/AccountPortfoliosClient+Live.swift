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

		func setOrUpdateAccountPortfolio(_ portfolio: OnLedgerEntity.Account) {
			portfoliosSubject.value.updateValue(portfolio, forKey: portfolio.address)
		}

		func setOrUpdateAccountPortfolios(_ portfolios: [OnLedgerEntity.Account]) {
			var newValue = portfoliosSubject.value
			for portfolio in portfolios {
				newValue[portfolio.address] = portfolio
			}
			portfoliosSubject.value = newValue
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

				await state.setOrUpdateAccountPortfolios(accounts)

				return accounts
			},
			fetchAccountPortfolio: { accountAddress, forceRefresh in
				if forceRefresh {
					cacheClient.removeFolder(.onLedgerEntity(.account(accountAddress.asGeneral)))
				}

				let portfolio = try await onLedgerEntitiesClient.getAccount(accountAddress)
				await state.setOrUpdateAccountPortfolio(portfolio)

				return portfolio
			},
			portfolioForAccount: { address in
				await state.portfolioForAccount(address)
			},
			portfolios: { state.portfoliosSubject.value.map(\.value) }
		)
	}()
}
