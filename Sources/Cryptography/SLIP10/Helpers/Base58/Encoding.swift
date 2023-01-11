import Foundation

// MARK: - Encoding
internal protocol Encoding {
	static var baseAlphabets: String { get }
	static var zeroAlphabet: Character { get }
	static var base: Int { get }

	// log(256) / log(base), rounded up
	static func sizeFromByte(size: Int) -> Int
	// log(base) / log(256), rounded up
	static func sizeFromBase(size: Int) -> Int

	// Public
	static func encode(_ bytes: Data) -> String
	static func decode(_ string: String) -> Data?
}

// The Base encoding used is home made, and has some differences. Especially,
// leading zeros are kept as single zeros when conversion happens.
extension Encoding {
	static func convertBytesToBase(_ bytes: Data) -> [UInt8] {
		var length = 0
		let size = sizeFromByte(size: bytes.count)
		var encodedBytes: [UInt8] = Array(repeating: 0, count: size)

		for b in bytes {
			var carry = Int(b)
			var i = 0
			for j in (0 ... encodedBytes.count - 1).reversed() where carry != 0 || i < length {
				carry += 256 * Int(encodedBytes[j])
				encodedBytes[j] = UInt8(carry % base)
				carry /= base
				i += 1
			}

			assert(carry == 0)

			length = i
		}

		var zerosToRemove = 0
		for b in encodedBytes {
			if b != 0 { break }
			zerosToRemove += 1
		}

		encodedBytes.removeFirst(zerosToRemove)
		return encodedBytes
	}

	static func encode(_ bytes: Data) -> String {
		var bytes = bytes
		var zerosCount = 0

		for b in bytes {
			if b != 0 { break }
			zerosCount += 1
		}

		bytes.removeFirst(zerosCount)

		let encodedBytes = convertBytesToBase(bytes)

		var str = ""
		while zerosCount > 0 {
			str += String(zeroAlphabet)
			zerosCount -= 1
		}

		for b in encodedBytes {
			let index = String.Index(utf16Offset: Int(b), in: baseAlphabets)
			str += String(baseAlphabets[index])
		}

		return str
	}

	static func decode(_ string: String) -> Data? {
		guard !string.isEmpty else { return nil }

		var zerosCount = 0
		var length = 0
		for c in string {
			if c != zeroAlphabet { break }
			zerosCount += 1
		}
		let size = sizeFromBase(size: string.lengthOfBytes(using: .utf8) - zerosCount)
		var decodedBytes: [UInt8] = Array(repeating: 0, count: size)
		for c in string {
			guard let baseIndex: Int = baseAlphabets.firstIndex(of: c)?.utf16Offset(in: baseAlphabets) else { return nil }
			var carry = baseIndex
			var i = 0
			for j in (0 ... decodedBytes.count - 1).reversed() where carry != 0 || i < length {
				carry += base * Int(decodedBytes[j])
				decodedBytes[j] = UInt8(carry % 256)
				carry /= 256
				i += 1
			}

			assert(carry == 0)
			length = i
		}

		// skip leading zeros
		var zerosToRemove = 0

		for b in decodedBytes {
			if b != 0 { break }
			zerosToRemove += 1
		}
		decodedBytes.removeFirst(zerosToRemove)

		return Data(repeating: 0, count: zerosCount) + Data(decodedBytes)
	}
}
