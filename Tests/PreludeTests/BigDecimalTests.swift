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

	func test_round_bigdecimal() throws {
		func doTest(_ bigDecimalString: String, divisibility: UInt, expected expectedString: String, line: UInt = #line) throws {
			let expected = try BigDecimal(fromString: expectedString)
			var actual = try BigDecimal(fromString: bigDecimalString)
			try actual.roundToDivisibility(divisibility)
			XCTAssertEqual(actual, expected, line: line)
		}

		try doTest("1000.123456789", divisibility: 0, expected: "1000")
		try doTest("1000.123456789", divisibility: 1, expected: "1000.1")
		try doTest("1000.123456789", divisibility: 2, expected: "1000.12")
		try doTest("1000.123456789", divisibility: 3, expected: "1000.123")
		try doTest("1000.123456789", divisibility: 4, expected: "1000.1235")
		try doTest("1000.123456789", divisibility: 5, expected: "1000.12346")
		try doTest("1000.123456789", divisibility: 20, expected: "1000.123456789")

		try doTest("1234568.123456789", divisibility: 0, expected: "1234568")
		try doTest("1234568.123456789", divisibility: 1, expected: "1234568.1")
		try doTest("1234568.123456789", divisibility: 2, expected: "1234568.12")
		try doTest("1234568.123456789", divisibility: 3, expected: "1234568.123")
		try doTest("1234568.123456789", divisibility: 4, expected: "1234568.1235")
		try doTest("1234568.123456789", divisibility: 5, expected: "1234568.12346")
		try doTest("1234568.123456789", divisibility: 20, expected: "1234568.123456789")

		try doTest("1234568456.123456789", divisibility: 0, expected: "1234568456")
		try doTest("1234568456.123456789", divisibility: 1, expected: "1234568456.1")
		try doTest("1234568456.123456789", divisibility: 2, expected: "1234568456.12")
		try doTest("1234568456.123456789", divisibility: 3, expected: "1234568456.123")
		try doTest("1234568456.123456789", divisibility: 4, expected: "1234568456.1235")
		try doTest("1234568456.123456789", divisibility: 5, expected: "1234568456.12346")
		try doTest("1234568456.123456789", divisibility: 20, expected: "1234568456.123456789")

		try doTest("9999999.9999999", divisibility: 0, expected: "10000000")
		try doTest("9999999.9999999", divisibility: 1, expected: "10000000")
		try doTest("9999999.9999999", divisibility: 2, expected: "10000000")
		try doTest("9999999.9999999", divisibility: 3, expected: "10000000")
		try doTest("9999999.9999999", divisibility: 4, expected: "10000000")
		try doTest("9999999.9999999", divisibility: 5, expected: "10000000")
		try doTest("9999999.9999999", divisibility: 20, expected: "9999999.9999999")

		try doTest("1000.12000", divisibility: 0, expected: "1000")
		try doTest("1000.12000", divisibility: 1, expected: "1000.1")
		try doTest("1000.12000", divisibility: 2, expected: "1000.12")
		try doTest("1000.12000", divisibility: 3, expected: "1000.12")
		try doTest("1000.12000", divisibility: 4, expected: "1000.12")
		try doTest("1000.12000", divisibility: 5, expected: "1000.12")
		try doTest("1000.12000", divisibility: 20, expected: "1000.12")
	}

	func test_truncate_bigdecimal() throws {
		func doTest(_ bigDecimalString: String, divisibility: UInt, expected expectedString: String, line: UInt = #line) throws {
			let expected = try BigDecimal(fromString: expectedString)
			var actual = try BigDecimal(fromString: bigDecimalString)
			try actual.truncateToDivisibility(divisibility)
			XCTAssertEqual(actual, expected, line: line)
		}

		try doTest("1000.123456789", divisibility: 0, expected: "1000")
		try doTest("1000.123456789", divisibility: 1, expected: "1000.1")
		try doTest("1000.123456789", divisibility: 2, expected: "1000.12")
		try doTest("1000.123456789", divisibility: 3, expected: "1000.123")
		try doTest("1000.123456789", divisibility: 4, expected: "1000.1234")
		try doTest("1000.123456789", divisibility: 5, expected: "1000.12345")
		try doTest("1000.123456789", divisibility: 20, expected: "1000.123456789")

		try doTest("1234568.123456789", divisibility: 0, expected: "1234568")
		try doTest("1234568.123456789", divisibility: 1, expected: "1234568.1")
		try doTest("1234568.123456789", divisibility: 2, expected: "1234568.12")
		try doTest("1234568.123456789", divisibility: 3, expected: "1234568.123")
		try doTest("1234568.123456789", divisibility: 4, expected: "1234568.1234")
		try doTest("1234568.123456789", divisibility: 5, expected: "1234568.12345")
		try doTest("1234568.123456789", divisibility: 20, expected: "1234568.123456789")

		try doTest("1234568456.123456789", divisibility: 0, expected: "1234568456")
		try doTest("1234568456.123456789", divisibility: 1, expected: "1234568456.1")
		try doTest("1234568456.123456789", divisibility: 2, expected: "1234568456.12")
		try doTest("1234568456.123456789", divisibility: 3, expected: "1234568456.123")
		try doTest("1234568456.123456789", divisibility: 4, expected: "1234568456.1234")
		try doTest("1234568456.123456789", divisibility: 5, expected: "1234568456.12345")
		try doTest("1234568456.123456789", divisibility: 20, expected: "1234568456.123456789")

		try doTest("9999999.9999999", divisibility: 0, expected: "9999999")
		try doTest("9999999.9999999", divisibility: 1, expected: "9999999.9")
		try doTest("9999999.9999999", divisibility: 2, expected: "9999999.99")
		try doTest("9999999.9999999", divisibility: 3, expected: "9999999.999")
		try doTest("9999999.9999999", divisibility: 4, expected: "9999999.9999")
		try doTest("9999999.9999999", divisibility: 5, expected: "9999999.99999")
		try doTest("9999999.9999999", divisibility: 20, expected: "9999999.9999999")

		try doTest("1000.12000", divisibility: 0, expected: "1000")
		try doTest("1000.12000", divisibility: 1, expected: "1000.1")
		try doTest("1000.12000", divisibility: 2, expected: "1000.12")
		try doTest("1000.12000", divisibility: 3, expected: "1000.12")
		try doTest("1000.12000", divisibility: 4, expected: "1000.12")
		try doTest("1000.12000", divisibility: 5, expected: "1000.12")
		try doTest("1000.12000", divisibility: 20, expected: "1000.12")
	}

	func test_parse_formatted_bigdecimal() throws {
		func doTest(_ formattedString: String, locale: Locale, expected: BigDecimal, line: UInt = #line) throws {
			let result = try BigDecimal(formattedString: formattedString, locale: locale)
			XCTAssertEqual(result, expected, line: line)
		}
		let spanish = Locale(identifier: "es")
		let us = Locale(identifier: "en_US_POSIX")
		try doTest("1,001", locale: spanish, expected: BigDecimal(fromString: "1.001"))
		try doTest("1,001", locale: us, expected: BigDecimal(fromString: "1001"))
		try doTest("1.001,45", locale: spanish, expected: BigDecimal(fromString: "1001.45"))
		try doTest("1.001,45", locale: us, expected: BigDecimal(fromString: "1.00145"))
	}

	func test_format_bigdecimal() throws {
		func doTest(_ bigDecimalString: String, expected: String, line: UInt = #line) throws {
			let locale = Locale(identifier: "en_US_POSIX")
			let bigDecimal = try BigDecimal(fromString: bigDecimalString)
			let actual = bigDecimal.formatted(roundedTo: 8, locale: locale)
			XCTAssertEqual(actual, expected, line: line)
		}

		try doTest("0.123456789", expected: "0.1234568")
		try doTest("0.4321", expected: "0.4321")
		try doTest("0.0000000000001", expected: "0")
		try doTest("0.9999999999999", expected: "1")
		try doTest("1000", expected: "1000")
		try doTest("1000.01", expected: "1000.01")
		try doTest("1000.123456789", expected: "1000.1235")
		try doTest("1000000.1234", expected: "1.0000001 M")
		try doTest("10000000.1234", expected: "10 M")
		try doTest("10000000.5234", expected: "10.000001 M")
		try doTest("999.999999999943", expected: "1000")

		try doTest("-0.123456789", expected: "-0.1234568")
		try doTest("-0.4321", expected: "-0.4321")
		try doTest("-0.0000000000001", expected: "0")
		try doTest("-0.9999999999999", expected: "-1")
		try doTest("-1000", expected: "-1000")
		try doTest("-1000.01", expected: "-1000.01")
		try doTest("-1000.123456789", expected: "-1000.1235")
		try doTest("-1000000.1234", expected: "-1.0000001 M")
		try doTest("-10000000.1234", expected: "-10 M")
		try doTest("-10000000.5234", expected: "-10.000001 M")
		try doTest("-999.999999999943", expected: "-1000")

		// No suffix
		try doTest("1.11222111222111222333222333", expected: "1.1122211")
		try doTest("11.1222111222111222333222333", expected: "11.122211")
		try doTest("111.222111222111222333222333", expected: "111.22211")
		try doTest("1112.22111222111222333222333", expected: "1112.2211")
		try doTest("11122.2111222111222333222333", expected: "11122.211")
		try doTest("111222.111222111222333222333", expected: "111222.11")

		// Million
		try doTest("1112221.11222111222333222333", expected: "1.1122211 M")
		try doTest("11122211.1222111222333222333", expected: "11.122211 M")
		try doTest("111222111.222111222333222333", expected: "111.22211 M")

		// Billion
		try doTest("1112221112.22111222333222333", expected: "1.1122211 B")
		try doTest("11122211122.2111222333222333", expected: "11.122211 B")
		try doTest("111222111222.111222333222333", expected: "111.22211 B")

		// Trillion
		try doTest("1112221112221.11222333222333", expected: "1.1122211 T")
		try doTest("11122211122211.1222333222333", expected: "11.122211 T")
		try doTest("111222111222111.222333222333", expected: "111.22211 T")
		try doTest("1112221112221112.22333222333", expected: "1112.2211 T")
		try doTest("11122211122211122.2333222333", expected: "11122.211 T")
		try doTest("111222111222111222.333222333", expected: "111222.11 T")
		try doTest("1112221112221112223.33222333", expected: "1112221.1 T")
		try doTest("11122211122211122233.3222333", expected: "11122211 T")

		// Too large, we have to use engineering notation
		try doTest("111222111222111222333.222333", expected: "1.112e20")
		try doTest("1112221112221112223332.22333", expected: "1.112e21")
		try doTest("11122211122211122233322.2333", expected: "1.112e22")
		try doTest("111222111222111222333222.333", expected: "1.112e23")
		try doTest("1112221112221112223332223.33", expected: "1.112e24")
		try doTest("11122211122211122233322233.3", expected: "1.112e25")
		try doTest("111222111222111222333222333", expected: "1.112e26")

		try doTest("999999999999999999999.922333", expected: "1e21")
		try doTest("9999999999999999999999.92333", expected: "1e22")
		try doTest("99999999999999999999999.9333", expected: "1e23")
		try doTest("999999999999999999999999.933", expected: "1e24")
		try doTest("9999999999999999999999999.93", expected: "1e25")
		try doTest("99999999999999999999999999.9", expected: "1e26")
		try doTest("999999999999999999999999999", expected: "1e27")

		try doTest("99999994", expected: "99.999994 M")
		try doTest("999999956", expected: "999.99996 M")

		try doTest("9999999462", expected: "9.9999995 B")
		try doTest("100123454", expected: "100.12345 M")
		try doTest("1000123446", expected: "1.0001234 B")
		try doTest("10001234462", expected: "10.001234 B")

		try doTest("100123456", expected: "100.12346 M")
		try doTest("1000123450", expected: "1.0001235 B")
		try doTest("10000123500", expected: "10.000124 B")

		try doTest("9999999900", expected: "9.9999999 B")
		try doTest("9999999900", expected: "9.9999999 B")
		try doTest("9999999900", expected: "9.9999999 B")
		try doTest("9999999500", expected: "9.9999995 B")
		try doTest("9999999400", expected: "9.9999994 B")
		try doTest("9999999000", expected: "9.999999 B")

		try doTest("10000012445.678", expected: "10.000012 B")
		try doTest("10000012445.678", expected: "10.000012 B")
		try doTest("10000012445.678", expected: "10.000012 B")
		try doTest("10000002445.678", expected: "10.000002 B")
		try doTest("10000002445.678", expected: "10.000002 B")

		try doTest("10000012545.678", expected: "10.000013 B")
		try doTest("10000012545.678", expected: "10.000013 B")
		try doTest("10000012545.678", expected: "10.000013 B")
		try doTest("10000002545.678", expected: "10.000003 B")
		try doTest("10000002545.678", expected: "10.000003 B")
		try doTest("10000000055.678", expected: "10 B")

		try doTest("999999999900.00", expected: "1 T")
		try doTest("999999999000.00", expected: "1 T")
		try doTest("999999990000.00", expected: "999.99999 B")
		try doTest("999999950000.00", expected: "999.99995 B")
		try doTest("999999940000.00", expected: "999.99994 B")
		try doTest("999999900000.00", expected: "999.9999 B")

		try doTest("9999999999900.00", expected: "10 T")
		try doTest("9999999999000.00", expected: "10 T")
		try doTest("9999999990000.00", expected: "10 T")
		try doTest("9999999950000.00", expected: "10 T")
		try doTest("9999999940000.00", expected: "9.9999999 T")
		try doTest("9999999900000.00", expected: "9.9999999 T")

		try doTest("10000012445678.9", expected: "10.000012 T")
		try doTest("10000012445678.92", expected: "10.000012 T")
		try doTest("10000012445678.923", expected: "10.000012 T")
		try doTest("10000002445678.9", expected: "10.000002 T")
		try doTest("10000000445678.92", expected: "10 T")
		try doTest("10000000045678.923", expected: "10 T")

		try doTest("10000012545678", expected: "10.000013 T")
		try doTest("10000012545678.2", expected: "10.000013 T")
		try doTest("10000012545678.23", expected: "10.000013 T")
		try doTest("10000002545678", expected: "10.000003 T")
		try doTest("10000002545678.2", expected: "10.000003 T")
		try doTest("10000000055678.23", expected: "10 T")

		try doTest("01434.234", expected: "1434.234")
		try doTest("1434.234", expected: "1434.234")
		try doTest("112.234", expected: "112.234")
		try doTest("12.234", expected: "12.234")
		try doTest("1.234", expected: "1.234")
		try doTest("0.01", expected: "0.01")
		try doTest("0.001", expected: "0.001")
		try doTest("0.00100", expected: "0.001")
		try doTest("0.001000", expected: "0.001")

		try doTest("57896044618.658097719968", expected: "57.896045 B")
		try doTest("1000000000.1", expected: "1 B")
		try doTest("999999999.1", expected: "1 B")
		try doTest("1000000000", expected: "1 B")

		try doTest("1000.1234", expected: "1000.1234")
		try doTest("1000.5", expected: "1000.5")
		try doTest("0.12345674", expected: "0.1234567")
		try doTest("0.12345675", expected: "0.1234568")
		try doTest("0.4321", expected: "0.4321")
		try doTest("0.99999999999999999", expected: "1")
		try doTest("0.00000000000000001", expected: "0")
		try doTest("0", expected: "0")
		try doTest("1", expected: "1")
		try doTest("0.0", expected: "0")
		try doTest("1.0", expected: "1")
	}

	func test_format_grouping_separator() throws {
		func doTest(_ bigDecimalString: String, expected: String, line: UInt = #line) throws {
			let locale = Locale(identifier: "en_US_POSIX")
			let bigDecimal = try BigDecimal(fromString: bigDecimalString)
			let actual = bigDecimal.formatted(roundedTo: 8, locale: locale, usingGroupingSeparator: true)
			XCTAssertEqual(actual, expected, line: line)
		}

		try doTest("123456789", expected: "123.45679 M")
		try doTest("12345678", expected: "12.345678 M")
		try doTest("1234567", expected: "1.234567 M")

		try doTest("123456", expected: "123,456")
		try doTest("12345", expected: "12,345")
		try doTest("1234", expected: "1,234")
		try doTest("123", expected: "123")

		try doTest("123456.4321", expected: "123,456.43")
		try doTest("12345.4321", expected: "12,345.432")
		try doTest("1234.4321", expected: "1,234.4321")
		try doTest("123.4321", expected: "123.4321")
	}

	func test_format_bigdecimal_with_currency() throws {
		func doTest(_ bigDecimalString: String, expected: String, line: UInt = #line) throws {
			let locale = Locale(identifier: "en_US_POSIX")
			let bigDecimal = try BigDecimal(fromString: bigDecimalString)
			XCTAssertEqual(bigDecimal.format(fiatCurrency: .usd, locale: locale), expected, line: line)
		}

		try doTest("57896044618658097711785492504343953926634992332820282019728.792003956564819968", expected: "$57896044618658097711785492504343953926634992332820282019728.8") // rounded `0.79` -> `0.80`
		try doTest("1000000000.1", expected: "$1000000000.1")
		try doTest("1000000000", expected: "$1000000000")
		try doTest("1000.1234", expected: "$1000.1234")
		try doTest("1000.5", expected: "$1000.5")
		try doTest("0.1234567", expected: "$0.1234567")
		try doTest("0.4321", expected: "$0.4321")
		try doTest("0.99999999999999999", expected: "$1")
		try doTest("0.00000000000000001", expected: "$0")
	}

	func test_format_bigdecimal_with_divisibility() throws {
		func doTest(_ bigDecimalString: String, divisibility: Int, expected: String, line: UInt = #line) throws {
			let locale = Locale(identifier: "en_US_POSIX")
			let bigDecimal = try BigDecimal(fromString: bigDecimalString)
			XCTAssertEqual(bigDecimal.format(divisibility: divisibility, locale: locale), expected, line: line)
		}

		/// Big divisibility does not affect the basic result
		try doTest("57896044618658097711785492504343953926634992332820282019728", divisibility: 18, expected: "57896044618658097711785492504343953926634992332820282019728")
		try doTest("57896044618658097711785492504343953926634992332820282019728.0", divisibility: 18, expected: "57896044618658097711785492504343953926634992332820282019728")

		try doTest(
			"57896044618658097711785492504343953926634992332820282019728.792003956564819968",
			divisibility: 18,
			expected: "57896044618658097711785492504343953926634992332820282019728.8"
		) // rounded `0.79` -> `0.80`
		try doTest("1000000000.1", divisibility: 18, expected: "1000000000.1")
		try doTest("1000000000", divisibility: 18, expected: "1000000000")
		try doTest("1000.1234", divisibility: 18, expected: "1000.1234")
		try doTest("1000.5", divisibility: 18, expected: "1000.5")
		try doTest("0.1234567", divisibility: 18, expected: "0.1234567")
		try doTest("0.4321", divisibility: 18, expected: "0.4321")
		try doTest("0.99999999999999999", divisibility: 18, expected: "1")
		try doTest("0.00000000000000001", divisibility: 18, expected: "0")
		try doTest("0", divisibility: 18, expected: "0")
		try doTest("1", divisibility: 18, expected: "1")
		try doTest("0.0", divisibility: 18, expected: "0")
		try doTest("1.0", divisibility: 18, expected: "1")

		/// Zero divisibility.
		/// Specifying decimal places for a resource with divisibility zero is actually invalid. No transaction will succeed with such value
		try doTest("0.99999999999999999", divisibility: 0, expected: "0")
		try doTest("1.99999999999999999", divisibility: 0, expected: "1")
		/// Minimal divisibility
		try doTest("1.99999999999999999", divisibility: 1, expected: "1.9")
		/// Divisibility < Max formatted digits
		try doTest("1.12345678", divisibility: 4, expected: "1.1234")
		/// Max formatted digits
		try doTest("1.12345678", divisibility: 8, expected: "1.1234568")
	}

	func test_new_format_bigdecimal() throws {
		func doTest(_ bigDecimalString: String, expected: String, line: UInt = #line) throws {
			let locale = Locale(identifier: "en_US_POSIX")
			let bigDecimal = try BigDecimal(fromString: bigDecimalString)
			XCTAssertEqual(bigDecimal.format(locale: locale), expected, line: line)
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

	func test_new_formatt_bigdecimal_with_currency() throws {
		func doTest(_ bigDecimalString: String, expected: String, line: UInt = #line) throws {
			let locale = Locale(identifier: "en_US_POSIX")
			let bigDecimal = try BigDecimal(fromString: bigDecimalString)
			XCTAssertEqual(bigDecimal.format(fiatCurrency: .usd, locale: locale), expected, line: line)
		}

		try doTest("57896044618658097711785492504343953926634992332820282019728.792003956564819968", expected: "$57896044618658097711785492504343953926634992332820282019728.8") // rounded `0.79` -> `0.80`
		try doTest("1000000000.1", expected: "$1000000000.1")
		try doTest("1000000000", expected: "$1000000000")
		try doTest("1000.1234", expected: "$1000.1234")
		try doTest("1000.5", expected: "$1000.5")
		try doTest("0.1234567", expected: "$0.1234567")
		try doTest("0.4321", expected: "$0.4321")
		try doTest("0.99999999999999999", expected: "$1")
		try doTest("0.00000000000000001", expected: "$0")
	}

	func test_new_format_bigdecimal_with_divisibility() throws {
		func doTest(_ bigDecimalString: String, divisibility: Int, expected: String, line: UInt = #line) throws {
			let locale = Locale(identifier: "en_US_POSIX")
			let bigDecimal = try BigDecimal(fromString: bigDecimalString)
			XCTAssertEqual(bigDecimal.format(divisibility: divisibility, locale: locale), expected, line: line)
		}

		/// Big divisibility does not affect the basic result
		try doTest("57896044618658097711785492504343953926634992332820282019728", divisibility: 18, expected: "57896044618658097711785492504343953926634992332820282019728")
		try doTest("57896044618658097711785492504343953926634992332820282019728.0", divisibility: 18, expected: "57896044618658097711785492504343953926634992332820282019728")

		try doTest(
			"57896044618658097711785492504343953926634992332820282019728.792003956564819968",
			divisibility: 18,
			expected: "57896044618658097711785492504343953926634992332820282019728.8"
		) // rounded `0.79` -> `0.80`
		try doTest("1000000000.1", divisibility: 18, expected: "1000000000.1")
		try doTest("1000000000", divisibility: 18, expected: "1000000000")
		try doTest("1000.1234", divisibility: 18, expected: "1000.1234")
		try doTest("1000.5", divisibility: 18, expected: "1000.5")
		try doTest("0.1234567", divisibility: 18, expected: "0.1234567")
		try doTest("0.4321", divisibility: 18, expected: "0.4321")
		try doTest("0.99999999999999999", divisibility: 18, expected: "1")
		try doTest("0.00000000000000001", divisibility: 18, expected: "0")
		try doTest("0", divisibility: 18, expected: "0")
		try doTest("1", divisibility: 18, expected: "1")
		try doTest("0.0", divisibility: 18, expected: "0")
		try doTest("1.0", divisibility: 18, expected: "1")

		/// Zero divisibility.
		/// Specifying decimal places for a resource with divisibility zero is actually invalid. No transaction will succeed with such value
		try doTest("0.99999999999999999", divisibility: 0, expected: "0")
		try doTest("1.99999999999999999", divisibility: 0, expected: "1")
		/// Minimal divisibility
		try doTest("1.99999999999999999", divisibility: 1, expected: "1.9")
		/// Divisibility < Max formatted digits
		try doTest("1.12345678", divisibility: 4, expected: "1.1234")
		/// Max formatted digits
		try doTest("1.12345678", divisibility: 8, expected: "1.1234568")
	}
}
