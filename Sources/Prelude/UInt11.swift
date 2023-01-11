// MARK: - UInt11
public struct UInt11: Hashable, ExpressibleByIntegerLiteral {
	public let valueBoundBy16Bits: UInt16

	internal init?(valueBoundBy16Bits: UInt16) {
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
public extension UInt11 {
	init?<T>(exactly source: T) where T: BinaryInteger {
		guard let valueBoundBy16Bits = UInt16(exactly: source) else { return nil }
		self.init(valueBoundBy16Bits: valueBoundBy16Bits)
	}

	init<T>(truncatingIfNeeded source: T) where T: BinaryInteger {
		let valueBoundBy16Bits = UInt16(truncatingIfNeeded: source)
		self.valueBoundBy16Bits = Swift.min(UInt11.max16, valueBoundBy16Bits)
	}

	/// Creates a new integer value from the given string and radix.
	init?<S>(_ text: S, radix: Int = 10) where S: StringProtocol {
		guard let uint16 = UInt16(text, radix: radix) else { return nil }
		self.init(valueBoundBy16Bits: uint16)
	}

	init(integerLiteral value: Int) {
		guard let exactly = UInt11(exactly: value) else {
			fatalError("bad integer literal value does not fit in UInt11, value passed was: \(value)")
		}
		self = exactly
	}

	init?<S>(bits: S) where S: Collection, S.Element == Bool {
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

extension Sequence where Element == Bool {
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

public extension Int {
	static let bitsPerByte = 8
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
