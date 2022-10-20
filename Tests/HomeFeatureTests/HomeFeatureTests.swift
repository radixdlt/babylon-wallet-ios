import AccountDetailsFeature
import AccountListFeature
import AccountPortfolio
import Asset
import ComposableArchitecture
import FungibleTokenListFeature
@testable import HomeFeature
import NonFungibleTokenListFeature
import Profile
import TestUtils

@MainActor
final class HomeFeatureTests: TestCase {
	let account = try! OnNetwork.Account(
		address: OnNetwork.Account.EntityAddress(
			address: "account_tdx_a_1qwv0unmwmxschqj8sntg6n9eejkrr6yr6fa4ekxazdzqhm6wy5"
		),
		securityState: .unsecured(.init(
			genesisFactorInstance: .curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorInstance(.init(
				factorSourceReference: .init(
					factorSourceKind: .curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSourceKind,
					factorSourceID: "09bfa80bcc9b75d6ad82d59730f7b179cbc668ba6ad4008721d5e6a179ff55f1"
				),
				publicKey: .curve25519(.init(
					compressedRepresentation: Data(
						hexString: "7bf9f97c0cac8c6c112d716069ccc169283b9838fa2f951c625b3d4ca0a8f05b")
				)),
				derivationPath: .accountPath(.init(derivationPath: "m/44H/1022H/10H/525H/0H/1238H"))
			)
			)
		)),
		index: 0,
		derivationPath: .init(derivationPath: "m/44H/1022H/10H/525H/0H/1238H"),
		displayName: "Main"
	)
	var address: AccountAddress { account.address }

	func test_totalWorthLoaded_whenTotalWorthIsLoaded_thenUpdateAllSubStates() async {
		// given

		// fungible tokens
		let btc = FungibleToken.btc
		let eth = FungibleToken.eth
		let xrd = FungibleToken.xrd

		let btcContainer = FungibleTokenContainer(asset: btc, amount: 1.234, worth: 1.987)
		let ethContainer = FungibleTokenContainer(asset: eth, amount: 2.345, worth: 2.876)
		let xrdContainer = FungibleTokenContainer(asset: xrd, amount: 4.567, worth: 4.654)
		let expectedAggregatedValue: Float = 9.517

		// non fungible tokens
		let nft1 = NonFungibleToken.mock1
		let nft2 = NonFungibleToken.mock2
		let nft3 = NonFungibleToken.mock3
		let nftContainer1 = NonFungibleTokenContainer(asset: nft1, metadata: nil)
		let nftContainer2 = NonFungibleTokenContainer(asset: nft2, metadata: nil)
		let nftContainer3 = NonFungibleTokenContainer(asset: nft3, metadata: nil)

		let totalPortfolio: AccountPortfolioDictionary = [
			account.address: .init(
				fungibleTokenContainers: [btcContainer, ethContainer, xrdContainer],
				nonFungibleTokenContainers: [nftContainer1, nftContainer2, nftContainer3],
				poolShareContainers: [],
				badgeContainers: []
			),
		]

		let accountRowState = AccountList.Row.State(account: account)
		let accountDetailsState = AccountDetails.State(for: accountRowState)
		var initialState: Home.State = .placeholder
		initialState.accountDetails = accountDetailsState
		initialState.accountList = .init(nonEmptyOrderedSetOfAccounts: .init(rawValue: .init([account]))!)

		let environment = Home.Environment(
			walletClient: .unimplemented,
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
		_ = await store.send(.internal(.system(.totalPortfolioLoaded(totalPortfolio)))) { [address] in
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

				let nonFungibleRow = NonFungibleTokenList.Row.RowState(
					containers: accountPortfolio.nonFungibleTokenContainers
				)

				$0.accountDetails?.assets = .init(
					fungibleTokenList: .init(
						sections: [section0, section1]
					),
					nonFungibleTokenList: .init(
						rows: [nonFungibleRow]
					)
				)
			}
		}
	}

	func test_accountWorthLoaded_whenSingleAccountWorthIsLoaded_thenUpdateSingleAccount() async {
		// given
		let btc = FungibleToken.btc
		let eth = FungibleToken.eth
		let xrd = FungibleToken.xrd

		let btcContainer = FungibleTokenContainer(asset: btc, amount: 1.234, worth: 1.987)
		let ethContainer = FungibleTokenContainer(asset: eth, amount: 2.345, worth: 2.876)
		let xrdContainer = FungibleTokenContainer(asset: xrd, amount: 4.567, worth: 4.654)
		let expectedAggregatedValue: Float = 9.517

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
