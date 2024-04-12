@testable import Radix_Wallet_Dev
import Sargon
import XCTest

final class TokenPriceCientTests: XCTestCase {
	func test_zeroPrice() {
		validateDecimalPriceConversion(0, expected: Decimal192.zero)
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
		validateDecimalPriceConversion(1.99, expected: try! Decimal192("1.99"))
	}

	func test_withDecimalPlaces_2() {
		validateDecimalPriceConversion(1.000099, expected: try! Decimal192("1.000099"))
	}

	func test_belowOne_1() {
		validateDecimalPriceConversion(0.99, expected: 0.99)
	}

	func test_belowOne_2() {
		validateDecimalPriceConversion(0.000099, expected: try! Decimal192("0.000099"))
	}

	func test_closeToDecimal192Divisibility() {
		// 17 decimal places
		validateDecimalPriceConversion(1.12345678901234567, expected: try! Decimal192("1.1234567890123457"))
	}

	func test_maxDecimal192Divisibility() {
		// 18 decimal places
		validateDecimalPriceConversion(1.123456789012345678, expected: try! Decimal192("1.1234567890123457"))
	}

	func test_overMaxDecimal192Divisibility() {
		// 22 decimal places
		validateDecimalPriceConversion(1.1234567890123456789012, expected: try! Decimal192("1.1234567890123457"))
	}

	private func validateDecimalPriceConversion(
		_ price: Double,
		expected: Decimal192,
		file: StaticString = #filePath,
		line: UInt = #line
	) {
		let tokenPrice = tokenWithPrice(price)
		guard let decimalPrice = TokenPricesClient.TokenPrices(tokenPrice).first?.value else {
			XCTFail("Could'nt convert \(tokenPrice) to Decimal192", file: file, line: line)
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
