import Asset
import FungibleTokenListFeature
import TestUtils

final class FungibleTokenListSortingTests: TestCase {
	func test_sortTokensWithValues() {
		// given
		let btc = FungibleToken.btc
		let eth = FungibleToken.eth
		let ltc = FungibleToken.ltc
		let xrd = FungibleToken.xrd
		let dot = FungibleToken.dot

		let btcContainer = FungibleTokenContainer(owner: try! .init(address: "deadbeef-owner"), asset: btc, amountInAttos: nil, worth: 1)
		let ethContainer = FungibleTokenContainer(owner: try! .init(address: "deadbeef-owner"), asset: eth, amountInAttos: nil, worth: 2)
		let ltcContainer = FungibleTokenContainer(owner: try! .init(address: "deadbeef-owner"), asset: ltc, amountInAttos: nil, worth: 3)
		let xrdContainer = FungibleTokenContainer(owner: try! .init(address: "deadbeef-owner"), asset: xrd, amountInAttos: nil, worth: 4)
		let dotContainer = FungibleTokenContainer(owner: try! .init(address: "deadbeef-owner"), asset: dot, amountInAttos: nil, worth: 5)

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

		let btcContainer = FungibleTokenContainer(owner: try! .init(address: "deadbeef-owner"), asset: btc, amountInAttos: nil, worth: nil)
		let ethContainer = FungibleTokenContainer(owner: try! .init(address: "deadbeef-owner"), asset: eth, amountInAttos: nil, worth: nil)
		let ltcContainer = FungibleTokenContainer(owner: try! .init(address: "deadbeef-owner"), asset: ltc, amountInAttos: nil, worth: nil)
		let xrdContainer = FungibleTokenContainer(owner: try! .init(address: "deadbeef-owner"), asset: xrd, amountInAttos: nil, worth: nil)
		let dotContainer = FungibleTokenContainer(owner: try! .init(address: "deadbeef-owner"), asset: dot, amountInAttos: nil, worth: nil)

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

		let btcContainer = FungibleTokenContainer(owner: try! .init(address: "deadbeef-owner"), asset: btc, amountInAttos: nil, worth: nil)
		let ethContainer = FungibleTokenContainer(owner: try! .init(address: "deadbeef-owner"), asset: eth, amountInAttos: nil, worth: 2)
		let ltcContainer = FungibleTokenContainer(owner: try! .init(address: "deadbeef-owner"), asset: ltc, amountInAttos: nil, worth: 3)
		let xrdContainer = FungibleTokenContainer(owner: try! .init(address: "deadbeef-owner"), asset: xrd, amountInAttos: nil, worth: nil)
		let dotContainer = FungibleTokenContainer(owner: try! .init(address: "deadbeef-owner"), asset: dot, amountInAttos: nil, worth: nil)

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
