import Asset
import ComposableArchitecture
@testable import FungibleTokenListFeature
import TestUtils

final class FungibleTokenListSorterTests: TestCase {
	private var sut: FungibleTokenListSorter!

	override func setUpWithError() throws {
		try super.setUpWithError()
		sut = FungibleTokenListSorter.live
	}

	override func tearDownWithError() throws {
		sut = nil
		try super.tearDownWithError()
	}

	func test_sortTokensWithValues() {
		// given
		let btc = FungibleToken(address: .random, supply: .fixed(100), tokenDescription: nil, name: "Bitcoin", code: "BTC", iconURL: "")
		let eth = FungibleToken(address: .random, supply: .fixed(100), tokenDescription: nil, name: "Ethereum", code: "ETH", iconURL: "")
		let ltc = FungibleToken(address: .random, supply: .fixed(100), tokenDescription: nil, name: "Litecoin", code: "LTC", iconURL: "")
		let xrd = FungibleToken.xrd
		let dot = FungibleToken(address: .random, supply: .fixed(100), tokenDescription: nil, name: "Polkadot", code: "DOT", iconURL: "")

		let btcContainer = FungibleTokenContainer(asset: btc, amount: nil, worth: 1.987)
		let ethContainer = FungibleTokenContainer(asset: eth, amount: nil, worth: 2.876)
		let ltcContainer = FungibleTokenContainer(asset: ltc, amount: nil, worth: 3.765)
		let xrdContainer = FungibleTokenContainer(asset: xrd, amount: nil, worth: 4.654)
		let dotContainer = FungibleTokenContainer(asset: dot, amount: nil, worth: 5.543)

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
		let btc = FungibleToken(address: .random, supply: .fixed(100), tokenDescription: nil, name: "Bitcoin", code: "BTC", iconURL: "")
		let eth = FungibleToken(address: .random, supply: .fixed(100), tokenDescription: nil, name: "Ethereum", code: "ETH", iconURL: "")
		let ltc = FungibleToken(address: .random, supply: .fixed(100), tokenDescription: nil, name: "Litecoin", code: "LTC", iconURL: "")
		let xrd = FungibleToken.xrd
		let dot = FungibleToken(address: .random, supply: .fixed(100), tokenDescription: nil, name: "Polkadot", code: "DOT", iconURL: "")

		let btcContainer = FungibleTokenContainer(asset: btc, amount: nil, worth: nil)
		let ethContainer = FungibleTokenContainer(asset: eth, amount: nil, worth: nil)
		let ltcContainer = FungibleTokenContainer(asset: ltc, amount: nil, worth: nil)
		let xrdContainer = FungibleTokenContainer(asset: xrd, amount: nil, worth: nil)
		let dotContainer = FungibleTokenContainer(asset: dot, amount: nil, worth: nil)

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
		let btc = FungibleToken(address: .random, supply: .fixed(100), tokenDescription: nil, name: "Bitcoin", code: "BTC", iconURL: "")
		let eth = FungibleToken(address: .random, supply: .fixed(100), tokenDescription: nil, name: "Ethereum", code: "ETH", iconURL: "")
		let ltc = FungibleToken(address: .random, supply: .fixed(100), tokenDescription: nil, name: "Litecoin", code: "LTC", iconURL: "")
		let xrd = FungibleToken.xrd
		let dot = FungibleToken(address: .random, supply: .fixed(100), tokenDescription: nil, name: "Polkadot", code: "DOT", iconURL: "")

		let btcContainer = FungibleTokenContainer(asset: btc, amount: nil, worth: nil)
		let ethContainer = FungibleTokenContainer(asset: eth, amount: nil, worth: 2.345)
		let ltcContainer = FungibleTokenContainer(asset: ltc, amount: nil, worth: 3.456)
		let xrdContainer = FungibleTokenContainer(asset: xrd, amount: nil, worth: nil)
		let dotContainer = FungibleTokenContainer(asset: dot, amount: nil, worth: nil)

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
