import AccountDetailsFeature
import AccountListFeature
import AccountWorthFetcher
import Address
import AssetListFeature
import ComposableArchitecture
@testable import HomeFeature
import Profile
import TestUtils

@MainActor
final class HomeFeatureTests: TestCase {
	func test_totalWorthLoaded_whenTotalWorthIsLoaded_thenUpdateAllSubStates() async {
		// given
		let btc = Token(code: .btc, value: 1.234)
		let eth = Token(code: .eth, value: 2.345)
		let xrd = Token(code: .xrd, value: 4.567)

		let btcContainer = TokenWorthContainer(token: btc, valueInCurrency: 1.987)
		let ethContainer = TokenWorthContainer(token: eth, valueInCurrency: 2.876)
		let xrdContainer = TokenWorthContainer(token: xrd, valueInCurrency: 4.654)
		let expectedAggregatedValue: Float = 9.517

		let address: Address = "abcdefgh12345678"
		let account: Profile.Account = .init(address: address, name: "Test Account")
		let totalWorth: [Address: AccountPortfolioWorth] = [
			address: .init(tokenContainers: [btcContainer, ethContainer, xrdContainer]),
		]

		let accountRowState = AccountList.Row.State(account: account)
		let accountDetailsState = AccountDetails.State(for: accountRowState)
		var initialState: Home.State = .placeholder
		initialState.accountDetails = accountDetailsState
		initialState.accountList = .init(just: [account])
		let environment = Home.Environment(
			appSettingsClient: .unimplemented,
			accountWorthFetcher: .unimplemented,
			pasteboardClient: .unimplemented,
			assetListSorter: .live
		)
		let store = TestStore(
			initialState: initialState,
			reducer: Home.reducer,
			environment: environment
		)

		// when
		_ = await store.send(.internal(.system(.totalWorthLoaded(totalWorth)))) {
			// then
			// local dictionary
			$0.accountsWorthDictionary = totalWorth

			// aggregated value
			$0.aggregatedValue.value = expectedAggregatedValue

			// account list
			$0.accountList.accounts[id: address]!.aggregatedValue = totalWorth[address]!.worth
			let tokenContainers = totalWorth[address]!.tokenContainers
			$0.accountList.accounts[id: address]!.tokenContainers = tokenContainers

			// account details
			if let details = $0.accountDetails {
				// aggregated value
				let accountWorth = $0.accountsWorthDictionary[details.address]
				$0.accountDetails?.aggregatedValue.value = accountWorth?.worth

				// asset list
				let containers = totalWorth[address]!.tokenContainers
				let sortedContainers = environment.assetListSorter.sortTokens(containers)

				let section0 = AssetList.Section.State(
					id: .xrd, assets: [
						AssetList.Row.State(
							tokenContainer: sortedContainers[0].tokenContainers[0],
							currency: $0.accountDetails!.aggregatedValue.currency,
							isCurrencyAmountVisible: $0.accountDetails!.aggregatedValue.isCurrencyAmountVisible
						),
					]
				)

				let section1 = AssetList.Section.State(
					id: .nonXrd,
					assets: [
						AssetList.Row.State(
							tokenContainer: sortedContainers[1].tokenContainers[0],
							currency: $0.accountDetails!.aggregatedValue.currency,
							isCurrencyAmountVisible: $0.accountDetails!.aggregatedValue.isCurrencyAmountVisible
						),
						AssetList.Row.State(
							tokenContainer: sortedContainers[1].tokenContainers[1],
							currency: $0.accountDetails!.aggregatedValue.currency,
							isCurrencyAmountVisible: $0.accountDetails!.aggregatedValue.isCurrencyAmountVisible
						),
					]
				)

				$0.accountDetails?.assetList = .init(sections: [section0, section1])
			}
		}
	}

	func test_accountWorthLoaded_whenSingleAccountWorthIsLoaded_thenUpdateSingleAccount() async {
		// given
		let btc = Token(code: .btc, value: 1.234)
		let eth = Token(code: .eth, value: 2.345)
		let xrd = Token(code: .xrd, value: 4.567)

		let btcContainer = TokenWorthContainer(token: btc, valueInCurrency: 1.987)
		let ethContainer = TokenWorthContainer(token: eth, valueInCurrency: 2.876)
		let xrdContainer = TokenWorthContainer(token: xrd, valueInCurrency: 4.654)
		let expectedAggregatedValue: Float = 9.517

		let address: Address = "abcdefgh12345678"
		let accountWorth: [Address: AccountPortfolioWorth] = [
			address: .init(tokenContainers: [btcContainer, ethContainer, xrdContainer]),
		]

		let initialState: Home.State = .placeholder
		let store = TestStore(
			initialState: initialState,
			reducer: Home.reducer,
			environment: .unimplemented
		)

		_ = await store.send(.internal(.system(.accountWorthLoaded(accountWorth)))) {
			guard let key = accountWorth.first?.key else {
				XCTFail("Failed to fetch first account")
				return
			}
			$0.accountsWorthDictionary[key] = accountWorth.first?.value
		}

		await store.receive(.internal(.system(.totalWorthLoaded(store.state.accountsWorthDictionary)))) {
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
	 			accountWorthFetcher: .mock,
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
	 			accountWorthFetcher: .mock,
	 			pasteboardClient: .noop
	 		)
	 	)

	 	store.send(.visitHub(.coordinate(.displayHub)))
	 	store.receive(.coordinate(.displayVisitHub))
	 }
	 */
}
