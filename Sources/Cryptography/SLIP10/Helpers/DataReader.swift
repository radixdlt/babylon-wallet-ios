import Foundation

// MARK: - DataReader
public final class DataReader {
	private let source: Data
	public let sourceSize: Int
	public private(set) var offset: Int = 0
	public init(data: Data) {
		source = data
		sourceSize = data.count
	}
}

extension DataReader {
	public var isFinished: Bool {
		offset == sourceSize
	}

	public func readUInt<U>(byteCount: Int, endianess: Endianess = .big) throws -> U where U: FixedWidthInteger & UnsignedInteger {
		let bytes = try read(byteCount: byteCount)

		switch endianess {
		case .little:
			return bytes.withUnsafeBytes {
				$0.load(as: U.self)
			}
		case .big:
			var endianessSwappedBytes = bytes
			endianessSwappedBytes.reverse()
			return endianessSwappedBytes.withUnsafeBytes {
				$0.load(as: U.self)
			}
		}
	}

	public func readInt<I>(byteCount: Int, endianess: Endianess = .big) throws -> I where I: FixedWidthInteger & SignedInteger {
		let bytes = try read(byteCount: byteCount)

		let littleEndianInt = bytes.withUnsafeBytes {
			$0.load(as: I.self)
		}

		switch endianess {
		case .little:
			return littleEndianInt
		case .big:
			var endianessSwappedBytes = bytes
			endianessSwappedBytes.reverse()
			return endianessSwappedBytes.withUnsafeBytes {
				$0.load(as: I.self)
			}
		}
	}
}

// MARK: - Endianess
public enum Endianess {
	case big, little
}

extension String {
	public func trimWhitespacesIncludingNullTerminators() -> String {
		trimmingCharacters(in: .whitespacesAndNewlines.union(.init(charactersIn: .null)))
	}

	public static var null: String { String(.null) }
}

extension Character {
	public static var null: Self { Character(.init(0x00)) }
}

extension DataReader {
	public enum Error: Swift.Error {
		case failedToCreateRawRepresentableFromRawValue
		case dataReaderHasNoMoreBytesToBeRead
		case dataEmpty
		case failedToDecodeStringAsUTF8(asASCII: String?)
		case failedToDecodeStringAsEvenASCII
		case stringLongerThanExpectedMaxLength(got: Int, butExpectedAtMost: Int)
	}

	public func readByte() throws -> UInt8 {
		try readUInt8()
	}

	public func readUInt8() throws -> UInt8 {
		try readUInt(byteCount: 1, endianess: .big) // does not matter
	}

	public func readInt8(endianess: Endianess = .big) throws -> Int8 {
		try readInt(byteCount: 1, endianess: endianess)
	}

	public func readUInt16(endianess: Endianess = .big) throws -> UInt16 {
		try readUInt(byteCount: 2, endianess: endianess)
	}

	public func readInt16(endianess: Endianess = .big) throws -> Int16 {
		try readInt(byteCount: 2, endianess: endianess)
	}

	public func readUInt32(endianess: Endianess = .big) throws -> UInt32 {
		try readUInt(byteCount: 4, endianess: endianess)
	}

	public func readInt32(endianess: Endianess = .big) throws -> Int32 {
		try readInt(byteCount: 4, endianess: endianess)
	}

	public func read(byteCount: Int) throws -> Data {
		guard source.count >= byteCount else {
			throw Error.dataReaderHasNoMoreBytesToBeRead
		}
		let startIndex = Data.Index(offset)
		let endIndex = startIndex.advanced(by: byteCount)
		assert(endIndex <= source.count, "'source.count': \(source.count), but 'endIndex': \(endIndex)")
		self.offset += byteCount
		return Data(source[startIndex ..< endIndex])
	}

	public func readRest(throwIfEmpty: Bool = true) throws -> Data {
		let remainingByteCount = source.count - offset
		guard remainingByteCount > 0 else { throw Error.dataEmpty }
		return try read(byteCount: remainingByteCount)
	}

	public func readInt(endianess: Endianess = .big) throws -> Int {
		try readInt(byteCount: MemoryLayout<Int>.size, endianess: endianess)
	}

	public func readFloat() throws -> Float {
		var floatBytes = try read(byteCount: 4)
		let float: Float = floatBytes.withUnsafeMutableBytes {
			$0.load(as: Float.self)
		}
		return float
	}

	public func seek(to targetOffset: Int) throws {
		guard targetOffset < source.count else {
			throw Error.dataReaderHasNoMoreBytesToBeRead
		}

		self.offset = targetOffset
	}

	public func skip(byteCount: Int) throws {
		// Discard data
		let _ = try read(byteCount: byteCount)
	}

	public func read<R>(_ rawRepresentable: R.Type, endianess: Endianess = .big) throws -> R where R: RawRepresentable, R.RawValue: FixedWidthInteger & SignedInteger {
		let rawValue: R.RawValue = try readInt(byteCount: MemoryLayout<R.RawValue>.size, endianess: endianess)
		guard let rawRepresentable = R(rawValue: rawValue) else {
			throw Error.failedToCreateRawRepresentableFromRawValue
		}
		return rawRepresentable
	}

	public func read<R>(_ rawRepresentable: R.Type, endianess: Endianess = .big) throws -> R where R: RawRepresentable, R.RawValue: FixedWidthInteger & UnsignedInteger {
		let rawValue: R.RawValue = try readUInt(byteCount: MemoryLayout<R.RawValue>.size, endianess: endianess)
		guard let rawRepresentable = R(rawValue: rawValue) else {
			throw Error.failedToCreateRawRepresentableFromRawValue
		}
		return rawRepresentable
	}

	public func readStringOfKnownMaxLength(_ maxLength: UInt32, trim: Bool = true) throws -> String? {
		guard maxLength > 0 else { return nil }
		let data = try read(byteCount: .init(maxLength))

		if trim {
			let trimmedData = data.prefix(while: { $0 != 0x00 })

			guard let string = String(bytes: trimmedData, encoding: .utf8) else {
				throw Error.failedToDecodeStringAsUTF8(asASCII: .init(bytes: data, encoding: .ascii))
			}
			let trimmedString = string.trimWhitespacesIncludingNullTerminators()
			return trimmedString
		} else {
			guard let string = String(bytes: data, encoding: .utf8) ?? String(bytes: data, encoding: .nonLossyASCII) ?? String(bytes: data, encoding: .ascii) else {
				throw Error.failedToDecodeStringAsEvenASCII
			}
			return string
		}
	}

	public func readBool() throws -> Bool {
		try readUInt8() != 0
	}
}
