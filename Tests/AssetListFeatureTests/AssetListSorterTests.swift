import AccountWorthFetcher
@testable import AssetListFeature
import ComposableArchitecture
import TestUtils

final class AssetListSorterTests: TestCase {
	private var sut: AssetListSorter!

	override func setUpWithError() throws {
		try super.setUpWithError()
		sut = AssetListSorter.live
	}

	override func tearDownWithError() throws {
		sut = nil
		try super.tearDownWithError()
	}

	func test_sortTokensWithValues() {
		// given
		let btc = Token(code: .btc, value: 1.234)
		let eth = Token(code: .eth, value: 2.345)
		let ltc = Token(code: .ltc, value: 3.456)
		let xrd = Token(code: .xrd, value: 4.567)
		let dot = Token(code: .dot, value: 5.678)

		let btcContainer = TokenWorthContainer(token: btc, valueInCurrency: 1.987)
		let ethContainer = TokenWorthContainer(token: eth, valueInCurrency: 2.876)
		let ltcContainer = TokenWorthContainer(token: ltc, valueInCurrency: 3.765)
		let xrdContainer = TokenWorthContainer(token: xrd, valueInCurrency: 4.654)
		let dotContainer = TokenWorthContainer(token: dot, valueInCurrency: 5.543)

		// when
		let result = sut.sortTokens([btcContainer, ethContainer, ltcContainer, xrdContainer, dotContainer])

		// then
		let expectedResult = [
			AssetCategory(type: .xrd, tokenContainers: [xrdContainer]),
			AssetCategory(type: .nonXrd, tokenContainers: [dotContainer, ltcContainer, ethContainer, btcContainer]),
		]
		XCTAssertEqual(result, expectedResult)
	}

	func test_sortTokensWithNoValues() {
		// given
		let btc = Token(code: .btc, value: nil)
		let eth = Token(code: .eth, value: nil)
		let ltc = Token(code: .ltc, value: nil)
		let xrd = Token(code: .xrd, value: nil)
		let dot = Token(code: .dot, value: nil)

		let btcContainer = TokenWorthContainer(token: btc, valueInCurrency: nil)
		let ethContainer = TokenWorthContainer(token: eth, valueInCurrency: nil)
		let ltcContainer = TokenWorthContainer(token: ltc, valueInCurrency: nil)
		let xrdContainer = TokenWorthContainer(token: xrd, valueInCurrency: nil)
		let dotContainer = TokenWorthContainer(token: dot, valueInCurrency: nil)

		// when
		let result = sut.sortTokens([btcContainer, ethContainer, ltcContainer, xrdContainer, dotContainer])

		// then
		let expectedResult = [
			AssetCategory(type: .xrd, tokenContainers: [xrdContainer]),
			AssetCategory(type: .nonXrd, tokenContainers: [btcContainer, dotContainer, ethContainer, ltcContainer]),
		]
		XCTAssertEqual(result, expectedResult)
	}

	func test_sortTokensWithAndWithNoValues() {
		// given
		let btc = Token(code: .btc, value: nil)
		let eth = Token(code: .eth, value: 1.234)
		let ltc = Token(code: .ltc, value: 9.876)
		let xrd = Token(code: .xrd, value: nil)
		let dot = Token(code: .dot, value: nil)

		let btcContainer = TokenWorthContainer(token: btc, valueInCurrency: nil)
		let ethContainer = TokenWorthContainer(token: eth, valueInCurrency: 2.345)
		let ltcContainer = TokenWorthContainer(token: ltc, valueInCurrency: 3.456)
		let xrdContainer = TokenWorthContainer(token: xrd, valueInCurrency: nil)
		let dotContainer = TokenWorthContainer(token: dot, valueInCurrency: nil)

		// when
		let result = sut.sortTokens([btcContainer, ethContainer, ltcContainer, xrdContainer, dotContainer])

		// then
		let expectedResult = [
			AssetCategory(type: .xrd, tokenContainers: [xrdContainer]),
			AssetCategory(type: .nonXrd, tokenContainers: [ltcContainer, ethContainer, btcContainer, dotContainer]),
		]
		XCTAssertEqual(result, expectedResult)
	}
}
