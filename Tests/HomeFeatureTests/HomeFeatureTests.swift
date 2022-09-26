import AccountDetailsFeature
import AccountListFeature
import AccountPortfolio
import Address
import Asset
import ComposableArchitecture
import FungibleTokenListFeature
@testable import HomeFeature
import Profile
import TestUtils

@MainActor
final class HomeFeatureTests: TestCase {
	func test_totalWorthLoaded_whenTotalWorthIsLoaded_thenUpdateAllSubStates() async {
		// given
		let btc = FungibleToken(address: "btcaddress", supply: .fixed(100), tokenDescription: nil, name: "Bitcoin", code: "BTC", iconURL: "")
		let eth = FungibleToken(address: "ethaddress", supply: .fixed(100), tokenDescription: nil, name: "Ethereum", code: "ETH", iconURL: "")
		let xrd = FungibleToken.xrd

		let btcContainer = FungibleTokenContainer(asset: btc, amount: 1.234, worth: 1.987)
		let ethContainer = FungibleTokenContainer(asset: eth, amount: 2.345, worth: 2.876)
		let xrdContainer = FungibleTokenContainer(asset: xrd, amount: 4.567, worth: 4.654)
		let expectedAggregatedValue: Float = 9.517

		let address: Address = "abcdefgh12345678"
		let account: Profile.Account = .init(address: address, name: "Test Account")
		let totalPortfolio: AccountPortfolioDictionary = [
			address: .init(
				fungibleTokenContainers: [btcContainer, ethContainer, xrdContainer],
				nonFungibleTokenContainers: [],
				poolShareContainers: [],
				badgeContainers: []
			),
		]

		let accountRowState = AccountList.Row.State(account: account)
		let accountDetailsState = AccountDetails.State(for: accountRowState)
		var initialState: Home.State = .placeholder
		initialState.accountDetails = accountDetailsState
		initialState.accountList = .init(just: [account])
		let environment = Home.Environment(
			appSettingsClient: .unimplemented,
			accountPortfolioFetcher: .unimplemented,
			pasteboardClient: .unimplemented,
			fungibleTokenListSorter: .live
		)
		let store = TestStore(
			initialState: initialState,
			reducer: Home.reducer,
			environment: environment
		)

		// when
		_ = await store.send(.internal(.system(.totalPortfolioLoaded(totalPortfolio)))) {
			// then
			// local dictionary
			$0.accountPortfolioDictionary = totalPortfolio

			// aggregated value
			$0.aggregatedValue.value = expectedAggregatedValue

			// account list
			$0.accountList.accounts[id: address]!.aggregatedValue = totalPortfolio[address]!.worth
			let accountPortfolio = totalPortfolio[address]!
			$0.accountList.accounts[id: address]!.portfolio = accountPortfolio

			// account details
			if let details = $0.accountDetails {
				// aggregated value
				let accountWorth = $0.accountPortfolioDictionary[details.address]
				$0.accountDetails?.aggregatedValue.value = accountWorth?.worth

				// asset list
				let sortedCategories = environment.fungibleTokenListSorter.sortTokens(accountPortfolio.fungibleTokenContainers)

				let section0 = FungibleTokenList.Section.State(
					id: .xrd, assets: [
						FungibleTokenList.Row.State(
							container: sortedCategories[0].tokenContainers[0],
							currency: $0.accountDetails!.aggregatedValue.currency,
							isCurrencyAmountVisible: $0.accountDetails!.aggregatedValue.isCurrencyAmountVisible
						),
					]
				)

				let section1 = FungibleTokenList.Section.State(
					id: .nonXrd,
					assets: [
						FungibleTokenList.Row.State(
							container: sortedCategories[1].tokenContainers[0],
							currency: $0.accountDetails!.aggregatedValue.currency,
							isCurrencyAmountVisible: $0.accountDetails!.aggregatedValue.isCurrencyAmountVisible
						),
						FungibleTokenList.Row.State(
							container: sortedCategories[1].tokenContainers[1],
							currency: $0.accountDetails!.aggregatedValue.currency,
							isCurrencyAmountVisible: $0.accountDetails!.aggregatedValue.isCurrencyAmountVisible
						),
					]
				)

				$0.accountDetails?.assets = .init(fungibleTokenList: .init(sections: [section0, section1]))
			}
		}
	}

	func test_accountWorthLoaded_whenSingleAccountWorthIsLoaded_thenUpdateSingleAccount() async {
		// given
		let btc = FungibleToken(address: "btcaddress", supply: .fixed(100), tokenDescription: nil, name: "Bitcoin", code: "BTC", iconURL: "")
		let eth = FungibleToken(address: "ethaddress", supply: .fixed(100), tokenDescription: nil, name: "Ethereum", code: "ETH", iconURL: "")
		let xrd = FungibleToken.xrd

		let btcContainer = FungibleTokenContainer(asset: btc, amount: 1.234, worth: 1.987)
		let ethContainer = FungibleTokenContainer(asset: eth, amount: 2.345, worth: 2.876)
		let xrdContainer = FungibleTokenContainer(asset: xrd, amount: 4.567, worth: 4.654)
		let expectedAggregatedValue: Float = 9.517

		let address: Address = "abcdefgh12345678"
		let accountPortfolio: AccountPortfolioDictionary = [
			address: .init(
				fungibleTokenContainers: [btcContainer, ethContainer, xrdContainer],
				nonFungibleTokenContainers: [],
				poolShareContainers: [],
				badgeContainers: []
			),
		]

		let initialState: Home.State = .placeholder
		let store = TestStore(
			initialState: initialState,
			reducer: Home.reducer,
			environment: .unimplemented
		)

		_ = await store.send(.internal(.system(.accountPortfolioLoaded(accountPortfolio)))) {
			guard let key = accountPortfolio.first?.key else {
				XCTFail("Failed to fetch first account")
				return
			}
			$0.accountPortfolioDictionary[key] = accountPortfolio.first?.value
		}

		await store.receive(.internal(.system(.totalPortfolioLoaded(store.state.accountPortfolioDictionary)))) {
			$0.aggregatedValue.value = expectedAggregatedValue
		}
	}

	/*
	 func testSettingsButtonTapped() {
	 	let store = TestStore(
	 		initialState: Home.State(justA: .placeholder),
	 		reducer: Home.reducer,
	 		environment: Home.Environment(
	 			appSettingsClient: .mock,
	 			accountPortfolioFetcher: .mock,
	 			pasteboardClient: .noop
	 		)
	 	)

	 	store.send(.header(.coordinate(.displaySettings)))
	 	store.receive(.coordinate(.displaySettings))
	 }
	 */

	/*
	 func testVisitHubButtonTapped() {
	 	let store = TestStore(
	 		initialState: Home.State(justA: .placeholder),
	 		reducer: Home.reducer,
	 		environment: Home.Environment(
	 			appSettingsClient: .mock,
	 			accountPortfolioFetcher: .mock,
	 			pasteboardClient: .noop
	 		)
	 	)

	 	store.send(.visitHub(.coordinate(.displayHub)))
	 }
	 */
}
