import FeaturePrelude
import FungibleTokenListFeature
import TestingPrelude

final class FungibleTokenListSortingTests: TestCase {
	let account = OnNetwork.Account.testValue
	var address: AccountAddress { account.address }

	func test_sortTokensWithValues() {
		// given
		let btc = FungibleToken.btc
		let eth = FungibleToken.eth
		let ltc = FungibleToken.ltc
		let xrd = FungibleToken.xrd
		let dot = FungibleToken.dot

		let btcContainer = FungibleTokenContainer(owner: address, asset: btc, amount: nil, worth: 1)
		let ethContainer = FungibleTokenContainer(owner: address, asset: eth, amount: nil, worth: 2)
		let ltcContainer = FungibleTokenContainer(owner: address, asset: ltc, amount: nil, worth: 3)
		let xrdContainer = FungibleTokenContainer(owner: address, asset: xrd, amount: nil, worth: 4)
		let dotContainer = FungibleTokenContainer(owner: address, asset: dot, amount: nil, worth: 5)

		// when
		let result = [btcContainer, ethContainer, ltcContainer, xrdContainer, dotContainer].sortedIntoCategories()

		// then
		let expectedResult = [
			FungibleTokenCategory(type: .xrd, tokenContainers: [xrdContainer]),
			FungibleTokenCategory(type: .nonXrd, tokenContainers: [dotContainer, ltcContainer, ethContainer, btcContainer]),
		]
		XCTAssertEqual(result, expectedResult)
	}

	func test_sortTokensWithNoValues() {
		// given
		let btc = FungibleToken.btc
		let eth = FungibleToken.eth
		let ltc = FungibleToken.ltc
		let xrd = FungibleToken.xrd
		let dot = FungibleToken.dot

		let btcContainer = FungibleTokenContainer(owner: address, asset: btc, amount: nil, worth: nil)
		let ethContainer = FungibleTokenContainer(owner: address, asset: eth, amount: nil, worth: nil)
		let ltcContainer = FungibleTokenContainer(owner: address, asset: ltc, amount: nil, worth: nil)
		let xrdContainer = FungibleTokenContainer(owner: address, asset: xrd, amount: nil, worth: nil)
		let dotContainer = FungibleTokenContainer(owner: address, asset: dot, amount: nil, worth: nil)

		// when
		let result = [btcContainer, ethContainer, ltcContainer, xrdContainer, dotContainer].sortedIntoCategories()

		// then
		let expectedResult = [
			FungibleTokenCategory(type: .xrd, tokenContainers: [xrdContainer]),
			FungibleTokenCategory(type: .nonXrd, tokenContainers: [btcContainer, dotContainer, ethContainer, ltcContainer]),
		]
		XCTAssertEqual(result, expectedResult)
	}

	func test_sortTokensWithAndWithNoValues() {
		// given
		let btc = FungibleToken.btc
		let eth = FungibleToken.eth
		let ltc = FungibleToken.ltc
		let xrd = FungibleToken.xrd
		let dot = FungibleToken.dot

		let btcContainer = FungibleTokenContainer(owner: address, asset: btc, amount: nil, worth: nil)
		let ethContainer = FungibleTokenContainer(owner: address, asset: eth, amount: nil, worth: 2)
		let ltcContainer = FungibleTokenContainer(owner: address, asset: ltc, amount: nil, worth: 3)
		let xrdContainer = FungibleTokenContainer(owner: address, asset: xrd, amount: nil, worth: nil)
		let dotContainer = FungibleTokenContainer(owner: address, asset: dot, amount: nil, worth: nil)

		// when
		let result = [btcContainer, ethContainer, ltcContainer, xrdContainer, dotContainer].sortedIntoCategories()

		// then
		let expectedResult = [
			FungibleTokenCategory(type: .xrd, tokenContainers: [xrdContainer]),
			FungibleTokenCategory(type: .nonXrd, tokenContainers: [ltcContainer, ethContainer, btcContainer, dotContainer]),
		]
		XCTAssertEqual(result, expectedResult)
	}
}
