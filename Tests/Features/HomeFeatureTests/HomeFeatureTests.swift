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
				publicKey: .eddsaEd25519(.init(
					compressedRepresentation: Data(
						hex: "7bf9f97c0cac8c6c112d716069ccc169283b9838fa2f951c625b3d4ca0a8f05b")
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

	func test_fetchPortfolio() async {
		// given

		// fungible tokens
		let btcContainer = FungibleTokenContainer(owner: address, asset: .btc, amount: "1234", worth: 1234)
		let ethContainer = FungibleTokenContainer(owner: address, asset: .eth, amount: "2345", worth: 2345)
		let xrdContainer = FungibleTokenContainer(owner: address, asset: .xrd, amount: "3456", worth: 3456)
		let expectedAggregatedValue: Float = 7035

		// non fungible tokens
		let nftContainer1 = NonFungibleTokenContainer.mock1
		let nftContainer2 = NonFungibleTokenContainer.mock2
		let nftContainer3 = NonFungibleTokenContainer.mock3

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
		var initialState: Home.State = .previewValue
		initialState.accountDetails = accountDetailsState
		initialState.accountList = .init(nonEmptyOrderedSetOfAccounts: .init(rawValue: .init([account]))!)

		let store = TestStore(
			initialState: initialState,
			reducer: Home()
		)

		// when
		await store.send(.internal(.system(.fetchPortfolioResult(.success(totalPortfolio))))) { [address] in
			// then
			// local dictionary
			$0.accountPortfolioDictionary = totalPortfolio

			// account list
			let accountPortfolio = totalPortfolio[address]!
			$0.accountList.accounts[id: address]!.portfolio = accountPortfolio

			// account details
			if let details = $0.accountDetails {
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

				$0.accountDetails?.assets = .init(
					fungibleTokenList: .init(
						sections: [section0, section1]
					),
					nonFungibleTokenList: .init(
						rows: .init(uniqueElements: nonFungibleRows)
					)
				)
			}
		}
	}

	func test_accountWorthLoaded_whenSingleAccountWorthIsLoaded_thenUpdateSingleAccount() async {
		// given
		// fungible tokens
		let btcContainer = FungibleTokenContainer(owner: address, asset: .btc, amount: "1234", worth: 1234)
		let ethContainer = FungibleTokenContainer(owner: address, asset: .eth, amount: "2345", worth: 2345)
		let xrdContainer = FungibleTokenContainer(owner: address, asset: .xrd, amount: "3456", worth: 3456)

		let accountPortfolio: AccountPortfolioDictionary = [
			account.address: .init(
				fungibleTokenContainers: [btcContainer, ethContainer, xrdContainer],
				nonFungibleTokenContainers: [],
				poolShareContainers: [],
				badgeContainers: []
			),
		]

		let initialState: Home.State = .init()
		let store = TestStore(
			initialState: initialState,
			reducer: Home()
		)

		// when
		await store.send(.internal(.system(.fetchPortfolioResult(.success(accountPortfolio))))) {
			// then
			guard let key = accountPortfolio.first?.key else {
				XCTFail("Failed to fetch first account")
				return
			}
			$0.accountPortfolioDictionary[key] = accountPortfolio.first?.value
		}
	}
}
