import Prelude
import TestingPrelude

final class BigDecimalTests: TestCase {
	func testBreakDecimal() throws {
		// 2^256 -1
		let first = BigDecimal("115792089237316195423570985008687907853269984665640564039457584007913129639934")!
		let second = BigDecimal("1")!
		// 2^256 -2
		let expected = BigDecimal("115792089237316195423570985008687907853269984665640564039457584007913129639933")!
		XCTAssertEqual(first - second, expected)
	}

	func testBreakDecimalInt128WithDecimals() throws {
		// 2^128 -1 + 0.987654321
		let first = BigDecimal("340282366920938463463374607431768211455.987654321")!
		// 2^128 -2 + 0.123456789
		let second = BigDecimal("340282366920938463463374607431768211454.123456789")!
		let expected = BigDecimal("1.864197532")!
		XCTAssertEqual(first - second, expected)
	}

	func testAddition() {
		let numbers = [
			("12.34", "1.234", "13.574"),
			("12.34", "-1.234", "11.106"),
			("18446744073709551616.0", "1", "18446744073709551617.0"),
			("184467440737e3380", "0", "184467440737e3380"),
			(
				"57896044618658097711785492504343953926634992332820282019728.792003956564819967",
				"0.000000000000000001",
				"57896044618658097711785492504343953926634992332820282019728.792003956564819968"
			),
			(
				"-57896044618658097711785492504343953926634992332820282019728.792003956564819968",
				"57896044618658097711785492504343953926634992332820282019728.792003956564819968",
				"0"
			),
			(
				"0.123456789123456789",
				"0.987654321987654321",
				"1.111111111111111110"
			),
			(
				"1.157920892373163e77", // 2^256
				"0.0000000000000000001",
				"115792089237316300000000000000000000000000000000000000000000000000000000000000.0000000000000000001"
			),
		]

		numbers.forEach {
			let first = BigDecimal($0.0)!
			let second = BigDecimal($0.1)!
			let expected = BigDecimal($0.2)!
			XCTAssertEqual(first + second, expected)
		}
	}

	func testSubtraction() {
		let numbers = [
			("12.34", "1.234", "11.106"),
			("12.34", "-1.234", "13.574"),
			("18446744073709551617.0", "18446744073709551616.0", "1"),
			("184467440737e3380", "184467440737e3380", "0"),
			(
				"57896044618658097711785492504343953926634992332820282019728.792003956564819968",
				"0.000000000000000001",
				"57896044618658097711785492504343953926634992332820282019728.792003956564819967"
			),
			(
				"57896044618658097711785492504343953926634992332820282019728.792003956564819968",
				"57896044618658097711785492504343953926634992332820282019728.792003956564819968",
				"0"
			),
			(
				"1.111111111111111110",
				"0.123456789123456789",
				"0.987654321987654321"
			),
			(
				"115792089237316300000000000000000000000000000000000000000000000000000000000000.0000000000000000001",
				"1.157920892373163e77", // 2^256
				"0.0000000000000000001"
			),
		]

		numbers.forEach {
			let first = BigDecimal($0.0)!
			let second = BigDecimal($0.1)!
			let expected = BigDecimal($0.2)!
			XCTAssertEqual(first - second, expected)
		}
	}

	func testMultiplication() {
		let numbers = [
			("2", "1", "2"),
			("12.34", "1.234", "15.22756"),
			("2e1", "1", "20"),
			("3", ".333333", "0.999999"),
			("2389472934723", "209481029831", "500549251119075878721813"),
			("1e-450", "1e500", ".1e51"),
		]

		numbers.forEach {
			let first = BigDecimal($0.0)!
			let second = BigDecimal($0.1)!
			let result = BigDecimal($0.2)!
			XCTAssertEqual(first * second, result)
		}
	}

	func testDiv() {
		let numbers = [
			("0", "1", "0"),
			("0", "10", "0"),
			("2", "1", "2"),
			("2e1", "1", "2e1"),
			("10", "10", "1"),
			("100", "10.0", "1e1"),
			("20.0", "200", "0.1"),
			("4", "2", "2.0"),
			("15", "3", "5.0"),
			("1", "2", "0.5"),
			("1", "2e-2", "5e1"),
			("1", "0.2", "5"),
			("1.0", "0.02", "50"),
			("1", "0.020", "5e1"),
			("5.0", "4.00", "1.25"),
			("5.0", "4.000", "1.25"),
			("5", "4.000", "1.25"),
			("5", "4", "1.25"),
			("100", "5", "20"),
			("-50", "5", "-10"),
			("200", "-5", "-40.0"),
		]

		numbers.forEach {
			let first = BigDecimal($0.0)!
			let second = BigDecimal($0.1)!
			let result = BigDecimal($0.2)!
			XCTAssertEqual(first / second, result)
		}
	}

	func testEqual() {
		let numbers = [
			("0e1", "0.0"),
			("0e0", "0.0"),
			("0e-0", "0.0"),
			("-0901300e-3", "-901.3"),
			("-0e-1", "-0.0"),
		]

		numbers.forEach {
			let first = BigDecimal($0.0)!
			let second = BigDecimal($0.1)!
			XCTAssertEqual(first, second)
		}
	}

	func testNotEqual() {
		let numbers = [
			("2", ".2e2"),
			("1e45", "1e-900"),
			("1e+900", "1e-900"),
		]

		numbers.forEach {
			let first = BigDecimal($0.0)!
			let second = BigDecimal($0.1)!
			XCTAssertNotEqual(first, second)
		}
	}

	func test_format_bigdecimal() throws {
		func doTest(_ bigDecimalString: String, expected: String) throws {
			let bigDecimal = try BigDecimal(fromString: bigDecimalString)
			XCTAssertEqual(bigDecimal.format(locale: Locale(identifier: "en_US_POSIX")), expected)
		}

		try doTest("57896044618658097711785492504343953926634992332820282019728", expected: "57896044618658097711785492504343953926634992332820282019728")
		try doTest("57896044618658097711785492504343953926634992332820282019728.0", expected: "57896044618658097711785492504343953926634992332820282019728")

		try doTest("57896044618658097711785492504343953926634992332820282019728.792003956564819968", expected: "57896044618658097711785492504343953926634992332820282019728.8") // rounded `0.79` -> `0.80`
		try doTest("1000000000.1", expected: "1000000000.1")
		try doTest("1000000000", expected: "1000000000")
		try doTest("1000.1234", expected: "1000.1234")
		try doTest("1000.5", expected: "1000.5")
		try doTest("0.1234567", expected: "0.1234567")
		try doTest("0.4321", expected: "0.4321")
		try doTest("0.99999999999999999", expected: "1")
		try doTest("0.00000000000000001", expected: "0")
		try doTest("0", expected: "0")
		try doTest("1", expected: "1")
		try doTest("0.0", expected: "0")
		try doTest("1.0", expected: "1")
	}
}
