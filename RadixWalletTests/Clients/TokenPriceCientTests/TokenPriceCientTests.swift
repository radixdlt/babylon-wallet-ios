@testable import Radix_Wallet_Dev
import XCTest

final class TokenPriceCientTests: XCTestCase {
	func test_zeroPrice() {
		validateDecimalPriceConversion(0, expected: .zero())
	}

	func test_noDecimalPlaces_1() {
		validateDecimalPriceConversion(10, expected: 10)
	}

	func test_noDecimalPlaces_2() {
		validateDecimalPriceConversion(10000, expected: 10000)
	}

	func test_noDecimalPlaces_3() {
		validateDecimalPriceConversion(10_000_000, expected: 10_000_000)
	}

	func test_withDecimalPlaces_1() {
		validateDecimalPriceConversion(1.99, expected: try! .init(value: "1.99"))
	}

	func test_withDecimalPlaces_2() {
		validateDecimalPriceConversion(1.000099, expected: try! .init(value: "1.000099"))
	}

	func test_belowOne_1() {
		validateDecimalPriceConversion(0.99, expected: 0.99)
	}

	func test_belowOne_2() {
		validateDecimalPriceConversion(0.000099, expected: try! .init(value: "0.000099"))
	}

	// NOTE: All of the below values would be rounded to 14 decimal places
	//       As it seems that Swift number formatter for Double cannot express more decimals.
	func test_closeToRETDecimalDivisibility() {
		// 17 decimal places
		validateDecimalPriceConversion(1.12345678901234567, expected: try! .init(value: "1.12345678901235"))
	}

	func test_maxRETDecimalDivisibility() {
		// 18 decimal places
		validateDecimalPriceConversion(1.123456789012345678, expected: try! .init(value: "1.12345678901235"))
	}

	func test_overMaxRETDecimalDivisibility() {
		// 22 decimal places
		validateDecimalPriceConversion(1.1234567890123456789012, expected: try! .init(value: "1.12345678901235"))
	}

	private func validateDecimalPriceConversion(
		_ price: Double,
		expected: RETDecimal,
		file: StaticString = #filePath,
		line: UInt = #line
	) {
		let tokenPrice = tokenWithPrice(price)
		guard let decimalPrice = TokenPricesClient.TokenPrices(tokenPrice).first?.value else {
			XCTFail("Could'nt convert \(tokenPrice) to RETDecimal", file: file, line: line)
			return
		}
		XCTAssertEqual(
			decimalPrice,
			expected,
			"expected \(expected.formattedPlain()), got \(decimalPrice.formattedPlain())",
			file: file,
			line: line
		)
	}

	private func tokenWithPrice(_ price: Double) -> TokensPriceResponse {
		TokensPriceResponse(tokens: [
			TokensPriceResponse.TokenPrice(
				resourceAddress: try! .init(validatingAddress: "resource_rdx1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxradxrd"),
				price: price
			),
		])
	}
}
