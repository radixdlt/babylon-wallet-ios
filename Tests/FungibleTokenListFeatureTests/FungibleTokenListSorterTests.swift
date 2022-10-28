import Asset
@testable import FungibleTokenListFeature
import TestUtils

final class FungibleTokenListSorterTests: TestCase {
	private var sut: FungibleTokenListSorter!

	override func setUpWithError() throws {
		try super.setUpWithError()
		sut = FungibleTokenListSorter.liveValue
	}

	override func tearDownWithError() throws {
		sut = nil
		try super.tearDownWithError()
	}

	func test_sortTokensWithValues() {
		// given
		let btc = FungibleToken.btc
		let eth = FungibleToken.eth
		let ltc = FungibleToken.ltc
		let xrd = FungibleToken.xrd
		let dot = FungibleToken.dot

		let btcContainer = FungibleTokenContainer(asset: btc, amountInAttos: nil, worth: 1)
		let ethContainer = FungibleTokenContainer(asset: eth, amountInAttos: nil, worth: 2)
		let ltcContainer = FungibleTokenContainer(asset: ltc, amountInAttos: nil, worth: 3)
		let xrdContainer = FungibleTokenContainer(asset: xrd, amountInAttos: nil, worth: 4)
		let dotContainer = FungibleTokenContainer(asset: dot, amountInAttos: nil, worth: 5)

		// when
		let result = sut.sortTokens([btcContainer, ethContainer, ltcContainer, xrdContainer, dotContainer])

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

		let btcContainer = FungibleTokenContainer(asset: btc, amountInAttos: nil, worth: nil)
		let ethContainer = FungibleTokenContainer(asset: eth, amountInAttos: nil, worth: nil)
		let ltcContainer = FungibleTokenContainer(asset: ltc, amountInAttos: nil, worth: nil)
		let xrdContainer = FungibleTokenContainer(asset: xrd, amountInAttos: nil, worth: nil)
		let dotContainer = FungibleTokenContainer(asset: dot, amountInAttos: nil, worth: nil)

		// when
		let result = sut.sortTokens([btcContainer, ethContainer, ltcContainer, xrdContainer, dotContainer])

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

		let btcContainer = FungibleTokenContainer(asset: btc, amountInAttos: nil, worth: nil)
		let ethContainer = FungibleTokenContainer(asset: eth, amountInAttos: nil, worth: 2)
		let ltcContainer = FungibleTokenContainer(asset: ltc, amountInAttos: nil, worth: 3)
		let xrdContainer = FungibleTokenContainer(asset: xrd, amountInAttos: nil, worth: nil)
		let dotContainer = FungibleTokenContainer(asset: dot, amountInAttos: nil, worth: nil)

		// when
		let result = sut.sortTokens([btcContainer, ethContainer, ltcContainer, xrdContainer, dotContainer])

		// then
		let expectedResult = [
			FungibleTokenCategory(type: .xrd, tokenContainers: [xrdContainer]),
			FungibleTokenCategory(type: .nonXrd, tokenContainers: [ltcContainer, ethContainer, btcContainer, dotContainer]),
		]
		XCTAssertEqual(result, expectedResult)
	}
}
