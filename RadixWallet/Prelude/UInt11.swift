// MARK: - UInt11
public struct UInt11: Sendable, Hashable, ExpressibleByIntegerLiteral, Comparable {
	public static func < (lhs: Self, rhs: Self) -> Bool {
		lhs.valueBoundBy16Bits < rhs.valueBoundBy16Bits
	}

	public let valueBoundBy16Bits: UInt16

	public init?(valueBoundBy16Bits: UInt16) {
		if valueBoundBy16Bits > UInt11.max16 {
			return nil
		}
		self.valueBoundBy16Bits = valueBoundBy16Bits
	}
}

// MARK: - Static min/max
extension UInt11 {
	static var bitWidth: Int { 11 }
	static var max16: UInt16 { UInt16(2047) }
	static var max: UInt11 { UInt11(exactly: max16)! }
	static var min: UInt11 { 0 }
}

// MARK: - Convenience Init
extension UInt11 {
	public init?(exactly source: some BinaryInteger) {
		guard let valueBoundBy16Bits = UInt16(exactly: source) else { return nil }
		self.init(valueBoundBy16Bits: valueBoundBy16Bits)
	}

	public init(truncatingIfNeeded source: some BinaryInteger) {
		let valueBoundBy16Bits = UInt16(truncatingIfNeeded: source)
		self.valueBoundBy16Bits = Swift.min(UInt11.max16, valueBoundBy16Bits)
	}

	/// Creates a new integer value from the given string and radix.
	public init?(_ text: some StringProtocol, radix: Int = 10) {
		guard let uint16 = UInt16(text, radix: radix) else { return nil }
		self.init(valueBoundBy16Bits: uint16)
	}

	public init(integerLiteral value: Int) {
		guard let exactly = UInt11(exactly: value) else {
			fatalError("bad integer literal value does not fit in UInt11, value passed was: \(value)")
		}
		self = exactly
	}

	public init?(bits: some Collection<Bool>) {
		if bits.count > UInt11.bitWidth { return nil }
		self.init(bits.binaryString, radix: 2)
	}
}

extension UInt11 {
	var binaryString: String {
		let binaryString = String(valueBoundBy16Bits.binaryString.suffix(UInt11.bitWidth))
		assert(UInt16(binaryString, radix: 2)! == valueBoundBy16Bits, "incorrect conversion.")
		return binaryString
	}
}

extension Sequence<Bool> {
	var binaryString: String {
		map { $0 ? "1" : "0" }.joined()
	}
}

extension FixedWidthInteger {
	var byteCount: Int {
		Self.bitWidth / .bitsPerByte
	}

	// Inspired by: https://developer.apple.com/documentation/swift/fixedwidthinteger
	var binaryString: String {
		var result: [String] = []
		for i in 0 ..< byteCount {
			let byte = UInt8(truncatingIfNeeded: self >> (i * 8))
			let bitString = String(byte, radix: 2)
			let padding = String(repeating: "0",
			                     count: 8 - bitString.count)
			result.append(padding + bitString)
		}
		return result.reversed().joined()
	}
}

extension Int {
	public static let bitsPerByte = 8
}

extension Data {
	// Inspired by: https://developer.apple.com/documentation/swift/fixedwidthinteger
	var binaryString: String {
		var result: [String] = []
		for byte in self {
			let byteString = String(byte, radix: 2)
			let padding = String(repeating: "0",
			                     count: 8 - byteString.count)
			result.append(padding + byteString)
		}
		return result.joined()
	}
}
