import AccountDetailsFeature
import AccountListFeature
import AccountPortfolio
import FeatureTestingPrelude
import FungibleTokenListFeature
@testable import HomeFeature
import NonFungibleTokenListFeature

@MainActor
final class HomeFeatureTests: TestCase {
	let account = OnNetwork.Account.testValue
	var address: AccountAddress { account.address }

	func test_fetchPortfolio() async {
		// given

		// fungible tokens
		let btcContainer = FungibleTokenContainer(owner: address, asset: .btc, amount: 1234, worth: 1234)
		let ethContainer = FungibleTokenContainer(owner: address, asset: .eth, amount: 2345, worth: 2345)
		let xrdContainer = FungibleTokenContainer(owner: address, asset: .xrd, amount: 3456, worth: 3456)

		// non fungible tokens
		let nftContainer1 = NonFungibleTokenContainer.mock1
		let nftContainer2 = NonFungibleTokenContainer.mock2
		let nftContainer3 = NonFungibleTokenContainer.mock3

		let totalPortfolio: AccountPortfolioDictionary = [
			account.address: .init(
				fungibleTokenContainers: [btcContainer, ethContainer, xrdContainer],
				nonFungibleTokenContainers: [nftContainer1, nftContainer2, nftContainer3],
				poolUnitContainers: [],
				badgeContainers: []
			),
		]

		let accountRowState = AccountList.Row.State(account: account)
		let accountDetailsState = AccountDetails.State(for: accountRowState)
		var initialState: Home.State = .previewValue
		initialState.destination = .accountDetails(accountDetailsState)
		initialState.accountList = .init(accounts: .init(uniqueElements: [account].map(AccountList.Row.State.init(account:))))

		let store = TestStore(
			initialState: initialState,
			reducer: Home()
		)

		// when
		await store.send(.internal(.fetchPortfolioResult(.success(totalPortfolio)))) { [address] in
			// then
			// local dictionary
			$0.accountPortfolioDictionary = totalPortfolio

			// account list
			let accountPortfolio = totalPortfolio[address]!
			$0.accountList.accounts[id: address]!.portfolio = accountPortfolio

			// account details
//			if $0.accountDetails != nil {
			// asset list
			let sortedCategories = accountPortfolio.fungibleTokenContainers.elements.sortedIntoCategories()

			let section0 = FungibleTokenList.Section.State(
				id: .xrd, assets: [
					FungibleTokenList.Row.State(
						container: sortedCategories[0].tokenContainers[0],
						currency: .usd,
						isCurrencyAmountVisible: true
					),
				]
			)

			let section1 = FungibleTokenList.Section.State(
				id: .nonXrd,
				assets: [
					FungibleTokenList.Row.State(
						container: sortedCategories[1].tokenContainers[0],
						currency: .usd,
						isCurrencyAmountVisible: true
					),
					FungibleTokenList.Row.State(
						container: sortedCategories[1].tokenContainers[1],
						currency: .usd,
						isCurrencyAmountVisible: true
					),
				]
			)

			let nonFungibleRows: [NonFungibleTokenList.Row.State] = accountPortfolio.nonFungibleTokenContainers.elements.map { .init(container: $0) }

//				$0.accountDetails?.assets = .init(
//					fungibleTokenList: .init(
//						sections: [section0, section1]
//					),
//					nonFungibleTokenList: .init(
//						rows: .init(uniqueElements: nonFungibleRows)
//					)
//				)
//			}
		}
	}

	func test_accountWorthLoaded_whenSingleAccountWorthIsLoaded_thenUpdateSingleAccount() async {
		// given
		// fungible tokens
		let btcContainer = FungibleTokenContainer(owner: address, asset: .btc, amount: 1234, worth: 1234)
		let ethContainer = FungibleTokenContainer(owner: address, asset: .eth, amount: 2345, worth: 2345)
		let xrdContainer = FungibleTokenContainer(owner: address, asset: .xrd, amount: 3456, worth: 3456)

		let accountPortfolio: AccountPortfolioDictionary = [
			account.address: .init(
				fungibleTokenContainers: [btcContainer, ethContainer, xrdContainer],
				nonFungibleTokenContainers: [],
				poolUnitContainers: [],
				badgeContainers: []
			),
		]

		let initialState: Home.State = .init()
		let store = TestStore(
			initialState: initialState,
			reducer: Home()
		)

		// when
		await store.send(.internal(.fetchPortfolioResult(.success(accountPortfolio)))) {
			// then
			guard let key = accountPortfolio.first?.key else {
				XCTFail("Failed to fetch first account")
				return
			}
			$0.accountPortfolioDictionary[key] = accountPortfolio.first?.value
		}
	}
}
