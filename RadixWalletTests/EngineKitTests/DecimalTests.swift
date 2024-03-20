import Foundation
@testable import Radix_Wallet_Dev
import XCTest

// MARK: - DecimalTests
final class DecimalTests: TestCase {
//	func testBreakDecimal() throws {
//		// 2^256 -1
//		let first = try Decimal(value: "115792089237316195423570985008687907853269984665640564039457584007913129639934")
//		let second = try Decimal(value: "1")
//		// 2^256 -2
//		let expected = try Decimal(value: "115792089237316195423570985008687907853269984665640564039457584007913129639933")
//		XCTAssertEqual(try first - second, expected)
//	}

	func testBreakDecimalInt128WithDecimals() throws {
		// 2^128 -1 + 0.987654321
		let first = try RETDecimal(value: "340282366920938463463374607431768211455.987654321")
		// 2^128 -2 + 0.123456789
		let second = try RETDecimal(value: "340282366920938463463374607431768211454.123456789")
		let expected = try RETDecimal(value: "1.864197532")
		XCTAssertEqual(first - second, expected)
	}

	func testAddition() throws {
		func doTest(lhs lhsDecimalString: String, rhs rhsDecimalString: String, expected expectedString: String) throws {
			let lhs = try RETDecimal(value: lhsDecimalString)
			let rhs = try RETDecimal(value: rhsDecimalString)
			let expected = try RETDecimal(value: expectedString)
			XCTAssertEqual(lhs + rhs, expected)
		}

		try doTest(lhs: "12.34", rhs: "1.234", expected: "13.574")
		try doTest(lhs: "12.34", rhs: "-1.234", expected: "11.106")
		try doTest(lhs: "18446744073709551616.0", rhs: "1", expected: "18446744073709551617.0")
//		try doTest(lhs: "184467440737e33", rhs: "0", expected: "184467440737e33")
//		try doTest(
//			lhs: "57896044618658097711785492504343953926634992332820282019728.792003956564819967",
//			rhs: "0.000000000000000001",
//			expected: "57896044618658097711785492504343953926634992332820282019728.792003956564819968"
//		)
//		try doTest(
//			lhs: "-57896044618658097711785492504343953926634992332820282019728.792003956564819968",
//			rhs: "57896044618658097711785492504343953926634992332820282019728.792003956564819968",
//			expected: "0"
//		)
		try doTest(
			lhs: "0.123456789123456789",
			rhs: "0.987654321987654321",
			expected: "1.111111111111111110"
		)
//		try doTest(
//			lhs: "1.157920892373163e77", // 2^256
//			rhs: "0.0000000000000000001",
//			expected: "115792089237316300000000000000000000000000000000000000000000000000000000000000.0000000000000000001"
//		)
	}

	func testSubtraction() throws {
		func doTest(lhs lhsDecimalString: String, rhs rhsDecimalString: String, expected expectedString: String) throws {
			let lhs = try RETDecimal(value: lhsDecimalString)
			let rhs = try RETDecimal(value: rhsDecimalString)
			let expected = try RETDecimal(value: expectedString)
			XCTAssertEqual(lhs - rhs, expected)
		}

		try doTest(lhs: "12.34", rhs: "1.234", expected: "11.106")
		try doTest(lhs: "12.34", rhs: "-1.234", expected: "13.574")
		try doTest(lhs: "18446744073709551616.0", rhs: "1", expected: "18446744073709551615.0")
		try doTest(lhs: "18446744073709551616.0", rhs: "18446744073709551615.0", expected: "1")
//		try doTest(lhs: "184467440737e3380", rhs: "184467440737e3380", expected: "0")
//		try doTest(
//			lhs: "57896044618658097711785492504343953926634992332820282019728.792003956564819967",
//			rhs: "0.000000000000000001",
//			expected: "57896044618658097711785492504343953926634992332820282019728.792003956564819968"
//		)
//		try doTest(
//			lhs: "-57896044618658097711785492504343953926634992332820282019728.792003956564819968",
//			rhs: "57896044618658097711785492504343953926634992332820282019728.792003956564819968",
//			expected: "0"
//		)
		try doTest(
			lhs: "1.111111111111111110",
			rhs: "0.123456789123456789",
			expected: "0.987654321987654321"
		)
	}

	func testMultiplication() throws {
		func doTest(lhs lhsDecimalString: String, rhs rhsDecimalString: String, expected expectedString: String) throws {
			let lhs = try RETDecimal(value: lhsDecimalString)
			let rhs = try RETDecimal(value: rhsDecimalString)
			let expected = try RETDecimal(value: expectedString)
			XCTAssertEqual(lhs * rhs, expected)
		}

		try doTest(lhs: "2", rhs: "1", expected: "2")
		try doTest(lhs: "12.34", rhs: "1.234", expected: "15.22756")
//		try doTest(lhs: "2e1", rhs: "1", expected: "20")
		try doTest(lhs: "3", rhs: "0.333333", expected: "0.999999")
		try doTest(lhs: "2389472934723", rhs: "209481029831", expected: "500549251119075878721813")
//		try doTest(lhs: "1e-450", rhs: "1e500", expected: ".1e51")
	}

	func testDivision() throws {
		func doTest(lhs lhsDecimalString: String, rhs rhsDecimalString: String, expected expectedString: String) throws {
			let lhs = try RETDecimal(value: lhsDecimalString)
			let rhs = try RETDecimal(value: rhsDecimalString)
			let expected = try RETDecimal(value: expectedString)
			XCTAssertEqual(lhs / rhs, expected)
		}

		try doTest(lhs: "0", rhs: "1", expected: "0")
		try doTest(lhs: "0", rhs: "10", expected: "0")
		try doTest(lhs: "2", rhs: "1", expected: "2")
//		try doTest(lhs: "2e1", rhs: "1", expected: "2e1")
		try doTest(lhs: "10", rhs: "10", expected: "1")
//		try doTest(lhs: "100", rhs: "10.0", expected: "1e1")
		try doTest(lhs: "20.0", rhs: "200", expected: "0.1")
		try doTest(lhs: "4", rhs: "2", expected: "2.0")
		try doTest(lhs: "15", rhs: "3", expected: "5.0")
		try doTest(lhs: "1", rhs: "2", expected: "0.5")
//		try doTest(lhs: "1", rhs: "2e-2", expected: "5e1")
		try doTest(lhs: "1", rhs: "0.2", expected: "5")
		try doTest(lhs: "1.0", rhs: "0.02", expected: "50")
//		try doTest(lhs: "1", rhs: "0.020", expected: "5e1")
		try doTest(lhs: "5.0", rhs: "4.00", expected: "1.25")
		try doTest(lhs: "5.0", rhs: "4.000", expected: "1.25")
		try doTest(lhs: "5", rhs: "4.000", expected: "1.25")
		try doTest(lhs: "5", rhs: "4", expected: "1.25")
		try doTest(lhs: "100", rhs: "5", expected: "20")
		try doTest(lhs: "-50", rhs: "5", expected: "-10")
		try doTest(lhs: "200", rhs: "-5", expected: "-40.0")
	}

	func testEqual() throws {
		func doTest(_ value0String: String, _ value1String: String) throws {
			let value0 = try RETDecimal(value: value0String)
			let value1 = try RETDecimal(value: value1String)
			XCTAssertEqual(value0, value1)
		}

//		try doTest("0e1", "0.0")
//		try doTest("0e0", "0.0")
//		try doTest("0e-0", "0.0")
//		try doTest("-0901300e-3", "-901.3")
//		try doTest("-0e-1", "-0.0")
	}

	func testNotEqual() throws {
		func doTest(_ value0String: String, _ value1String: String) throws {
			let value0 = try RETDecimal(value: value0String)
			let value1 = try RETDecimal(value: value1String)
			XCTAssertNotEqual(value0, value1)
		}

		try doTest("0.12", "0.123")
//		try doTest("2", ".2e2")
//		try doTest("1e45", "1e-900")
//		try doTest("1e+900", "1e-900")
	}

	func test_round_decimal() throws {
		func doTest(_ decimalString: String, divisibility: UInt, expected expectedString: String, line: UInt = #line) throws {
			let expected = try RETDecimal(value: expectedString)
			let decimal = try RETDecimal(value: decimalString)
			let actual = decimal.rounded(decimalPlaces: divisibility)
			XCTAssertEqual(actual, expected, line: line)
		}

		try doTest("1000.123456789", divisibility: 0, expected: "1000")
		try doTest("1000.123456789", divisibility: 1, expected: "1000.1")
		try doTest("1000.123456789", divisibility: 2, expected: "1000.12")
		try doTest("1000.123456789", divisibility: 3, expected: "1000.123")
		try doTest("1000.123456789", divisibility: 4, expected: "1000.1235")
		try doTest("1000.123456789", divisibility: 5, expected: "1000.12346")
		try doTest("1000.123456789", divisibility: 15, expected: "1000.123456789")

		try doTest("1234568.123456789", divisibility: 0, expected: "1234568")
		try doTest("1234568.123456789", divisibility: 1, expected: "1234568.1")
		try doTest("1234568.123456789", divisibility: 2, expected: "1234568.12")
		try doTest("1234568.123456789", divisibility: 3, expected: "1234568.123")
		try doTest("1234568.123456789", divisibility: 4, expected: "1234568.1235")
		try doTest("1234568.123456789", divisibility: 5, expected: "1234568.12346")
		try doTest("1234568.123456789", divisibility: 15, expected: "1234568.123456789")

		try doTest("1234568456.123456789", divisibility: 0, expected: "1234568456")
		try doTest("1234568456.123456789", divisibility: 1, expected: "1234568456.1")
		try doTest("1234568456.123456789", divisibility: 2, expected: "1234568456.12")
		try doTest("1234568456.123456789", divisibility: 3, expected: "1234568456.123")
		try doTest("1234568456.123456789", divisibility: 4, expected: "1234568456.1235")
		try doTest("1234568456.123456789", divisibility: 5, expected: "1234568456.12346")
		try doTest("1234568456.123456789", divisibility: 15, expected: "1234568456.123456789")

		try doTest("9999999.9999999", divisibility: 0, expected: "10000000")
		try doTest("9999999.9999999", divisibility: 1, expected: "10000000")
		try doTest("9999999.9999999", divisibility: 2, expected: "10000000")
		try doTest("9999999.9999999", divisibility: 3, expected: "10000000")
		try doTest("9999999.9999999", divisibility: 4, expected: "10000000")
		try doTest("9999999.9999999", divisibility: 5, expected: "10000000")
		try doTest("9999999.9999999", divisibility: 15, expected: "9999999.9999999")

		try doTest("1000.12000", divisibility: 0, expected: "1000")
		try doTest("1000.12000", divisibility: 1, expected: "1000.1")
		try doTest("1000.12000", divisibility: 2, expected: "1000.12")
		try doTest("1000.12000", divisibility: 3, expected: "1000.12")
		try doTest("1000.12000", divisibility: 4, expected: "1000.12")
		try doTest("1000.12000", divisibility: 5, expected: "1000.12")
		try doTest("1000.12000", divisibility: 15, expected: "1000.12")
	}

	func test_truncate_decimal() throws {
		func doTest(_ decimalString: String, divisibility: UInt, expected expectedString: String, line: UInt = #line) throws {
			let expected = try RETDecimal(value: expectedString)
			let decimal = try RETDecimal(value: decimalString)
			let actual = decimal.floor(decimalPlaces: divisibility)
			XCTAssertEqual(actual, expected, line: line)
		}

		try doTest("1000.123456789", divisibility: 0, expected: "1000")
		try doTest("1000.123456789", divisibility: 1, expected: "1000.1")
		try doTest("1000.123456789", divisibility: 2, expected: "1000.12")
		try doTest("1000.123456789", divisibility: 3, expected: "1000.123")
		try doTest("1000.123456789", divisibility: 4, expected: "1000.1234")
		try doTest("1000.123456789", divisibility: 5, expected: "1000.12345")
		try doTest("1000.123456789", divisibility: 15, expected: "1000.123456789")

		try doTest("1234568.123456789", divisibility: 0, expected: "1234568")
		try doTest("1234568.123456789", divisibility: 1, expected: "1234568.1")
		try doTest("1234568.123456789", divisibility: 2, expected: "1234568.12")
		try doTest("1234568.123456789", divisibility: 3, expected: "1234568.123")
		try doTest("1234568.123456789", divisibility: 4, expected: "1234568.1234")
		try doTest("1234568.123456789", divisibility: 5, expected: "1234568.12345")
		try doTest("1234568.123456789", divisibility: 15, expected: "1234568.123456789")

		try doTest("1234568456.123456789", divisibility: 0, expected: "1234568456")
		try doTest("1234568456.123456789", divisibility: 1, expected: "1234568456.1")
		try doTest("1234568456.123456789", divisibility: 2, expected: "1234568456.12")
		try doTest("1234568456.123456789", divisibility: 3, expected: "1234568456.123")
		try doTest("1234568456.123456789", divisibility: 4, expected: "1234568456.1234")
		try doTest("1234568456.123456789", divisibility: 5, expected: "1234568456.12345")
		try doTest("1234568456.123456789", divisibility: 15, expected: "1234568456.123456789")

		try doTest("9999999.9999999", divisibility: 0, expected: "9999999")
		try doTest("9999999.9999999", divisibility: 1, expected: "9999999.9")
		try doTest("9999999.9999999", divisibility: 2, expected: "9999999.99")
		try doTest("9999999.9999999", divisibility: 3, expected: "9999999.999")
		try doTest("9999999.9999999", divisibility: 4, expected: "9999999.9999")
		try doTest("9999999.9999999", divisibility: 5, expected: "9999999.99999")
		try doTest("9999999.9999999", divisibility: 15, expected: "9999999.9999999")

		try doTest("1000.12000", divisibility: 0, expected: "1000")
		try doTest("1000.12000", divisibility: 1, expected: "1000.1")
		try doTest("1000.12000", divisibility: 2, expected: "1000.12")
		try doTest("1000.12000", divisibility: 3, expected: "1000.12")
		try doTest("1000.12000", divisibility: 4, expected: "1000.12")
		try doTest("1000.12000", divisibility: 5, expected: "1000.12")
		try doTest("1000.12000", divisibility: 15, expected: "1000.12")
	}

	func test_parse_formatted_decimal() throws {
		func doTest(_ formattedString: String, locale: Locale, expected: EngineToolkit.Decimal, line: UInt = #line) throws {
			let result = try RETDecimal(formattedString: formattedString, locale: locale)
			XCTAssertEqual(result, expected, line: line)
		}
		let spanish = Locale(identifier: "es")
		let us = Locale(identifier: "en_US_POSIX")
		try doTest(",005", locale: spanish, expected: .init(value: "0.005"))
		try doTest(".005", locale: us, expected: .init(value: "0.005"))
		try doTest("1,001", locale: spanish, expected: .init(value: "1.001"))
		try doTest("1,001", locale: us, expected: .init(value: "1001"))
		try doTest("1.001,45", locale: spanish, expected: .init(value: "1001.45"))
		try doTest("1.001,45", locale: us, expected: .init(value: "1.00145"))
	}

	func test_format_decimal() throws {
		func doTest(_ decimal: RETDecimal, expected: String, line: UInt = #line) throws {
			let locale = Locale(identifier: "en_US_POSIX")
			let actual = decimal.formatted(locale: locale, totalPlaces: 8, useGroupingSeparator: false)
			XCTAssertEqual(actual, expected, line: line)
		}
		func doTest(_ decimalString: String, expected: String, line: UInt = #line) throws {
			try doTest(RETDecimal(value: decimalString), expected: expected, line: line)
		}

		try doTest(RETDecimal.max(), expected: "3.138e39")
		try doTest("0.009999999999999", expected: "0.01")
		try doTest("12341234", expected: "12.341234 M")
		try doTest("1234123.4", expected: "1.2341234 M")
		try doTest("123456.34", expected: "123456.34")
		try doTest("12345.234", expected: "12345.234")
		try doTest("1234.1234", expected: "1234.1234")
		try doTest("123.41234", expected: "123.41234")
		try doTest("12.341234", expected: "12.341234")
		try doTest("1.2341234", expected: "1.2341234")

		try doTest("0.1234123", expected: "0.1234123")
		try doTest("0.0234123", expected: "0.0234123")
		try doTest("0.0034123", expected: "0.0034123")
		try doTest("0.0004123", expected: "0.0004123")
		try doTest("0.0000123", expected: "0.0000123")
		try doTest("0.0000023", expected: "0.0000023")
		try doTest("0.0000003", expected: "0.0000003")

		try doTest("1234123.44", expected: "1.2341234 M")
		try doTest("123456.344", expected: "123456.34")
		try doTest("12345.2344", expected: "12345.234")
		try doTest("1234.12344", expected: "1234.1234")
		try doTest("123.412344", expected: "123.41234")
		try doTest("12.3412344", expected: "12.341234")
		try doTest("1.23412344", expected: "1.2341234")

		try doTest("0.12341234", expected: "0.1234123")
		try doTest("0.02341234", expected: "0.0234123")
		try doTest("0.00341234", expected: "0.0034123")
		try doTest("0.00041234", expected: "0.0004123")
		try doTest("0.00001234", expected: "0.0000123")
		try doTest("0.00000234", expected: "0.0000023")
		try doTest("0.00000034", expected: "0.0000003")

		try doTest("9999999.99", expected: "10 M")
		try doTest("999999.999", expected: "1 M")
		try doTest("99999.9999", expected: "100000")
		try doTest("9999.99999", expected: "10000")
		try doTest("999.999999", expected: "1000")
		try doTest("99.9999999", expected: "100")
		try doTest("9.99999999", expected: "10")

		try doTest("0.99999999", expected: "1")
		try doTest("0.09999999", expected: "0.1")
		try doTest("0.00999999", expected: "0.01")
		try doTest("0.00099999", expected: "0.001")
		try doTest("0.00009999", expected: "0.0001")
		try doTest("0.00000999", expected: "0.00001")
		try doTest("0.00000099", expected: "0.000001")
		try doTest("0.00000009", expected: "0.0000001")

		try doTest("0.000000009", expected: "0")

		try doTest("12.3456789", expected: "12.345679")

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
		try doTest("1.112221112221112223", expected: "1.1122211")
		try doTest("11.12221112221112223", expected: "11.122211")
		try doTest("111.2221112221112223", expected: "111.22211")
		try doTest("1112.221112221112223", expected: "1112.2211")
		try doTest("11122.21112221112223", expected: "11122.211")
		try doTest("111222.1112221112223", expected: "111222.11")

		// Million
		try doTest("1112221.112221112223332223", expected: "1.1122211 M")
		try doTest("11122211.12221112223332223", expected: "11.122211 M")
		try doTest("111222111.2221112223332223", expected: "111.22211 M")

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
		func doTest(_ decimalString: String, expected: String, line: UInt = #line) throws {
			let locale = Locale(identifier: "en_US_POSIX")
			let decimal = try RETDecimal(value: decimalString)
			let actual = decimal.formatted(locale: locale, totalPlaces: 8, useGroupingSeparator: true)
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

	func test_decoding_to_retDecimal() throws {
		struct TestStruct: Codable, Equatable {
			let decimal: RETDecimal
			let optional: RETDecimal?
		}

		func doTest(_ string: String, decimal expectedDecimal: RETDecimal, optionalIsNil: Bool = false) throws {
			if let data = string.data(using: .utf8) {
				let actual = try JSONDecoder().decode(TestStruct.self, from: data)
				let expected = TestStruct(decimal: expectedDecimal, optional: optionalIsNil ? nil : expectedDecimal)
				XCTAssertEqual(actual, expected)
			} else {
				XCTFail()
			}
		}

		try doTest("{\"decimal\":\"123.1234\",\"optional\":\"123.1234\"}", decimal: .init(value: "123.1234"))
		try doTest("{\"decimal\":\"1233434.1234\",\"optional\":\"1233434.1234\"}", decimal: .init(value: "1233434.1234"))
		try doTest("{\"decimal\":\"124300.1332\",\"optional\":\"124300.1332\"}", decimal: .init(value: "124300.1332"))
		try doTest("{\"decimal\":\"000124300.1332000\",\"optional\":\"000124300.1332000\"}", decimal: .init(value: "000124300.1332000"))
		try doTest("{\"decimal\":\"124300.000001332\",\"optional\":\"124300.000001332\"}", decimal: .init(value: "124300.000001332"))
		try doTest("{\"decimal\":\"0.0000000223\",\"optional\":\"0.0000000223\"}", decimal: .init(value: "0.0000000223"))
		try doTest("{\"decimal\":\"0.000\",\"optional\":\"0.000\"}", decimal: .init(value: "0.000"))
		try doTest("{\"decimal\":\"0.0\",\"optional\":\"0.0\"}", decimal: .init(value: "0.0"))
		try doTest("{\"decimal\":\"0.009999999999999\",\"optional\":\"0.009999999999999\"}", decimal: .init(value: "0.009999999999999"))
		try doTest("{\"decimal\":\"1234123.4\",\"optional\":\"1234123.4\"}", decimal: .init(value: "1234123.4"))
		try doTest("{\"decimal\":\"123456.34\",\"optional\":\"123456.34\"}", decimal: .init(value: "123456.34"))
		try doTest("{\"decimal\":\"12345.234\",\"optional\":\"12345.234\"}", decimal: .init(value: "12345.234"))

		try doTest("{\"decimal\":\"12341234\",\"optional\":\"12341234\"}", decimal: .init(value: "12341234"))
		try doTest("{\"decimal\":\"1234123412341234\",\"optional\":\"1234123412341234\"}", decimal: .init(value: "1234123412341234"))

		try doTest("{\"decimal\":\"00000123\",\"optional\":\"00000123\"}", decimal: .init(value: "123"))
		try doTest("{\"decimal\":\"00000123.1234\",\"optional\":\"00000123.1234\"}", decimal: .init(value: "123.1234"))
		try doTest("{\"decimal\":\"00000123.12340000\",\"optional\":\"00000123.12340000\"}", decimal: .init(value: "123.1234"))
		try doTest("{\"decimal\":\"123.12340000\",\"optional\":\"123.12340000\"}", decimal: .init(value: "123.1234"))

		try doTest("{\"decimal\":\"123.1234\"}", decimal: .init(value: "123.1234"), optionalIsNil: true)
		try doTest("{\"decimal\":\"12341234\"}", decimal: .init(value: "12341234"), optionalIsNil: true)
	}

	func test_roundtrip_coding_retDecimal() throws {
		struct TestStruct: Codable, Equatable {
			let decimal: RETDecimal?
		}

		func doTest(_ decimal: RETDecimal?) throws {
			let original = TestStruct(decimal: decimal)
			let encoded = try JSONEncoder().encode(original)
			let decoded = try JSONDecoder().decode(TestStruct.self, from: encoded)
			XCTAssertEqual(original, decoded)
		}

		try doTest(nil)

		for decimalString in decimalStrings {
			try doTest(RETDecimal(value: decimalString))
		}
	}

	private var decimalStrings: [String] {
		[
			"123.1234",
			"1233434.1234",
			"124300.1332",
			"000124300.1332000",
			"124300.000001332",
			"0.0000000223",
			"0.000",
			"0.0",
			"0.009999999999999",
			"12341234",
			"1234123.4",
			"123456.34",
			"12345.234",
			"0.00000009",
			"0.000000009",
			"12.3456789",
			"0.123456789",
			"0.4321",
			"0.0000000000001",
			"0.9999999999999",
			"1000",
			"1000.01",
			"1000.123456789",
			"1000000.1234",
			"10000000.1234",
			"10000000.5234",
			"999.999999999943",
			"-0.123456789",
			"-0.4321",
			"-0.0000000000001",
			"-0.9999999999999",
			"-1000",
			"-1000.01",
			"-1000.123456789",
			"-1000000.1234",
			"1",
			"0.0",
			"1.0",
		]
	}
}
