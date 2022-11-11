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
		let ownedBTC = OwnedFungibleToken(owner: account.address, amountInAttos: 14.inAttos, token: .btc)
		let ownedETH = OwnedFungibleToken(owner: account.address, amountInAttos: 2, token: .eth)
		let ownedXRD = OwnedFungibleToken(owner: account.address, amountInAttos: 4, token: .xrd)

		// non fungible tokens
		let ownedNFT1 = OwnedNonFungibleToken(owner: account.address, nonFungibleIDS: ["1"], token: .mock1)
		let ownedNFT2 = OwnedNonFungibleToken(owner: account.address, nonFungibleIDS: ["3", "7"], token: .mock2)
		let ownedNFT3 = OwnedNonFungibleToken(owner: account.address, nonFungibleIDS: ["1337"], token: .mock3)

		let totalPortfolio: AccountPortfolioDictionary = [
			account.address: .init(ownedFungibleTokens: [ownedBTC, ownedETH, ownedXRD], ownedNonFungibleTokens: [ownedNFT1, ownedNFT2, ownedNFT3]),
		]

		let accountRowState = AccountList.Row.State(account: account)
		let accountDetailsState = AccountDetails.State(for: accountRowState)
		var initialState: Home.State = .placeholder
		initialState.accountDetails = accountDetailsState
		initialState.accountList = .init(nonEmptyOrderedSetOfAccounts: .init(rawValue: .init([account]))!)

		let store = TestStore(
			initialState: initialState,
			reducer: Home()
		)

		// when
		_ = await store.send(.internal(.system(.fetchPortfolioResult(.success(totalPortfolio))))) { [address] in
			// then
			// local dictionary
			$0.accountPortfolioDictionary = totalPortfolio

			// account list
			let accountPortfolio = totalPortfolio[address]!
			$0.accountList.accounts[id: address]!.portfolio = accountPortfolio

			// account details
			if let details = $0.accountDetails {
				// asset list
				let sortedCategories = accountPortfolio.fungibleTokenContainers.sortedIntoCategories()

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

				let nonFungibleRow = NonFungibleTokenList.Row.State(
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
		// fungible tokens
		let ownedBTC = OwnedFungibleToken(owner: account.address, amountInAttos: 14.inAttos, token: .btc)
		let ownedETH = OwnedFungibleToken(owner: account.address, amountInAttos: 2, token: .eth)
		let ownedXRD = OwnedFungibleToken(owner: account.address, amountInAttos: 4, token: .xrd)

		let accountPortfolio: AccountPortfolioDictionary = [
			account.address: .init(ownedFungibleTokens: [ownedBTC, ownedETH, ownedXRD], ownedNonFungibleTokens: []),
		]

		let initialState: Home.State = .placeholder
		let store = TestStore(
			initialState: initialState,
			reducer: Home()
		)

		// when
		_ = await store.send(.internal(.system(.fetchPortfolioResult(.success(accountPortfolio))))) {
			// then
			guard let key = accountPortfolio.first?.key else {
				XCTFail("Failed to fetch first account")
				return
			}
			$0.accountPortfolioDictionary[key] = accountPortfolio.first?.value
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

	func testVisitHubButtonTapped() async {
		let initialState: Home.State = .placeholder
		let store = TestStore(
			initialState: initialState,
			reducer: Home()
		)
		let openedURL = ActorIsolated<URL?>(nil)
		store.dependencies.openURL = .init { url in
			await openedURL.setValue(url)
			return true
		}

		_ = await store.send(.child(.visitHub(.delegate(.displayHub))))

		await openedURL.withValue { openedURL in
			XCTAssertEqual(openedURL, URL(string: "https://www.apple.com")!)
		}
	}
}
