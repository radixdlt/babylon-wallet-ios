//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftCrypto open source project
//
// Copyright (c) 2019-2022 Apple Inc. and the SwiftCrypto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.md for the list of SwiftCrypto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

// MARK: - ByteHexEncodingErrors
// https://github.com/apple/swift-crypto/blob/main/Sources/Crypto/Util/PrettyBytes.swift

// Changes made by Radix:
// * Changed `Data(hexString:)` to `Data(hex:)`
// * Changed `Data(hexString:)` init to handle `0x` prefixes.
// * Changed `ByteHexEncodingErrors` to `public`
// * Changed `func hexEncodedString` to `func hex`
// * Added computed property `var hex: String`

enum ByteHexEncodingErrors: Error, Equatable {
	case hexStringContainsOddNumberOfChars
	case incorrectHexValue
	case incorrectString
}

let charA = UInt8(UnicodeScalar("a").value)
let char0 = UInt8(UnicodeScalar("0").value)

private func htoi(_ value: UInt8) throws -> UInt8 {
	switch value {
	case char0 ... char0 + 9:
		return value - char0
	case charA ... charA + 5:
		return value - charA + 10
	default:
		throw ByteHexEncodingErrors.incorrectHexValue
	}
}

extension Data {
	init(
		hex hexString: String,
		lowercaseInput: Bool = true,
		trimWhitespaces: Bool = true,
		acceptLeading0x: Bool = true
	) throws {
		self.init()
		var hexString = trimWhitespaces ? hexString.replacingOccurrences(of: " ", with: "") : hexString

		if acceptLeading0x, hexString.starts(with: "0x") {
			hexString = String(hexString.dropFirst(2))
		}

		if hexString.isEmpty {
			self = Self()
			return
		}

		if hexString.count % 2 != 0 {
			throw ByteHexEncodingErrors.hexStringContainsOddNumberOfChars
		}

		if lowercaseInput {
			hexString = hexString.lowercased()
		}

		let stringBytes: [UInt8] = Array(hexString.data(using: .utf8)!)

		for i in 0 ... ((hexString.count / 2) - 1) {
			let char1 = stringBytes[2 * i]
			let char2 = stringBytes[2 * i + 1]

			try append(htoi(char1) << 4 + htoi(char2))
		}
	}
}

extension Data {
	struct HexEncodingOptions: OptionSet {
		typealias RawValue = Int
		let rawValue: RawValue
		init(rawValue: RawValue) {
			self.rawValue = rawValue
		}

		static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
	}

	func hex(options: HexEncodingOptions = []) -> String {
		let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
		return map { String(format: format, $0) }.joined()
	}

	var hex: String {
		hex()
	}
}

extension ContiguousBytes {
	var hex: String {
		data.hex
	}

	var data: Data {
		withUnsafeBytes {
			Data($0)
		}
	}

	var bytes: [UInt8] {
		withUnsafeBytes {
			[UInt8]($0)
		}
	}
}

extension FixedWidthInteger {
	var data: Data {
		let data = withUnsafeBytes(of: bigEndian) { Data($0) }
		return data
	}

	var bytes: [UInt8] {
		[UInt8](data)
	}
}

#if DEBUG
extension Data: ExpressibleByStringLiteral {
	public init(stringLiteral hex: String) {
		do {
			self = try Self(hex: hex)
		} catch {
			fatalError("Failed to create data, string was not a valid hexadecimal string, error: \(String(describing: error))")
		}
	}
}

extension String {
	static let deadbeef32Bytes = Self(repeating: "deadbeef", count: 8)
	static let deadbeef64Bytes = Self(repeating: "deadbeef", count: 16)
}

extension Data {
	static let deadbeef32Bytes = try! Self(hex: .deadbeef32Bytes)
	static let deadbeef64Bytes = try! Self(hex: .deadbeef64Bytes)
}

#endif // DEBUG
