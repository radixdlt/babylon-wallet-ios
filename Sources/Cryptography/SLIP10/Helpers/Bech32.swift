import Foundation

/// A set of Bech32 coding methods.
///
/// ```
/// // Encode bytes to address
/// let cashaddr: String = Bech32.encode(payload: [versionByte] + pubkeyHash,
///                                      prefix: "bitcoincash")
///
/// // Decode address to bytes
/// guard let payload: Data = Bech32.decode(text: address) else {
///     // Invalid checksum or Bech32 coding
///     throw SomeError()
/// }
/// let versionByte = payload[0]
/// let pubkeyHash = payload.dropFirst()
/// ```
public enum Bech32 {
	internal static let base32Alphabets = "qpzry9x8gf2tvdw0s3jn54khce6mua7l"

	/// Encodes the data to Bech32 encoded string
	///
	/// Creates checksum bytes from the prefix and the payload, and then puts the
	/// checksum bytes to the original data. Then, encode the combined data to
	/// Base32 string. At last, returns the combined string of prefix, separator
	/// and the encoded base32 text.
	/// ```
	/// let address = Base58Check.encode(payload: [versionByte] + pubkeyHash,
	///                                  prefix: "bitcoincash")
	/// ```
	/// - Parameters:
	///   - payload: The data to encode
	///   - prefix: The prefix of the encoded text. It is also used to create checksum.
	///   - separator: separator that separates prefix and Base32 encoded text
	public static func encode(payload: Data, prefix: String, separator: String = ":") -> String {
		let payloadUint5 = convertTo5bit(data: payload, pad: true)
		let checksumUint5: Data = createChecksum(prefix: prefix, payload: payloadUint5) // Data of [UInt5]
		let combined: Data = payloadUint5 + checksumUint5 // Data of [UInt5]
		var base32 = ""
		for b in combined {
			let index = String.Index(utf16Offset: Int(b), in: base32Alphabets)
			base32 += String(base32Alphabets[index])
		}

		return prefix + separator + base32
	}

	@available(*, unavailable, renamed: "encode(payload:prefix:separator:)")
	public static func encode(_ bytes: Data, prefix: String, seperator: String = ":") -> String {
		encode(payload: bytes, prefix: prefix, separator: seperator)
	}

	/// Decodes the Bech32 encoded string to original payload
	///
	/// ```
	/// // Decode address to bytes
	/// guard let payload: Data = Bech32.decode(text: address) else {
	///     // Invalid checksum or Bech32 coding
	///     throw SomeError()
	/// }
	/// let versionByte = payload[0]
	/// let pubkeyHash = payload.dropFirst()
	/// ```
	/// - Parameters:
	///   - string: The data to encode
	///   - separator: separator that separates prefix and Base32 encoded text
	public static func decode(_ string: String, separator: String = ":") -> (prefix: String, data: Data)? {
		// We can't have empty string.
		// Bech32 should be uppercase only / lowercase only.
		guard !string.isEmpty, [string.lowercased(), string.uppercased()].contains(string) else {
			return nil
		}

		let components = string.components(separatedBy: separator)
		// We can only handle string contains both scheme and base32
		guard components.count == 2 else {
			return nil
		}
		let (prefix, base32) = (components[0], components[1])

		var decodedIn5bit = [UInt8]()
		for c in base32.lowercased() {
			// We can't have characters other than base32 alphabets.
			guard let baseIndex = base32Alphabets.firstIndex(of: c)?.utf16Offset(in: base32Alphabets) else {
				return nil
			}
			decodedIn5bit.append(UInt8(baseIndex))
		}

		// We can't have invalid checksum
		let payload = Data(decodedIn5bit)
		guard verifyChecksum(prefix: prefix, payload: payload) else {
			return nil
		}

		// Drop checksum
		guard let bytes = try? convertFrom5bit(data: payload.dropLast(8)) else {
			return nil
		}
		return (prefix, Data(bytes))
	}

	@available(*, unavailable, renamed: "decode(string:separator:)")
	public static func decode(_ string: String, seperator: String = ":") -> (prefix: String, data: Data)? {
		decode(string, separator: seperator)
	}

	internal static func verifyChecksum(prefix: String, payload: Data) -> Bool {
		PolyMod(expand(prefix) + payload) == 0
	}

	internal static func expand(_ prefix: String) -> Data {
		var ret = Data()
		let buf: [UInt8] = Array(prefix.utf8)
		for b in buf {
			ret.append(b & 0x1F)
		}
		ret += Data(repeating: 0, count: 1)
		return ret
	}

	internal static func createChecksum(prefix: String, payload: Data) -> Data {
		let enc: Data = expand(prefix) + payload + Data(repeating: 0, count: 8)
		let mod: UInt64 = PolyMod(enc)
		var ret = Data()
		for i in 0 ..< 8 {
			ret.append(UInt8((mod >> (5 * (7 - i))) & 0x1F))
		}
		return ret
	}

	internal static func PolyMod(_ data: Data) -> UInt64 {
		var c: UInt64 = 1
		for d in data {
			let c0 = UInt8(c >> 35)
			c = ((c & 0x07_FFFF_FFFF) << 5) ^ UInt64(d)
			if c0 & 0x01 != 0 { c ^= 0x98_F2BC_8E61 }
			if c0 & 0x02 != 0 { c ^= 0x79_B76D_99E2 }
			if c0 & 0x04 != 0 { c ^= 0xF3_3E5F_B3C4 }
			if c0 & 0x08 != 0 { c ^= 0xAE_2EAB_E2A8 }
			if c0 & 0x10 != 0 { c ^= 0x1E_4F43_E470 }
		}
		return c ^ 1
	}

	internal static func convertTo5bit(data: Data, pad: Bool) -> Data {
		var acc = Int()
		var bits = UInt8()
		let maxv = 31 // 31 = 0x1f = 00011111
		var converted: [UInt8] = []
		for d in data {
			acc = (acc << 8) | Int(d)
			bits += 8

			while bits >= 5 {
				bits -= 5
				converted.append(UInt8(acc >> Int(bits) & maxv))
			}
		}

		let lastBits = UInt8(acc << (5 - bits) & maxv)
		if pad, bits > 0 {
			converted.append(lastBits)
		}
		return Data(converted)
	}

	internal static func convertFrom5bit(data: Data) throws -> Data {
		var acc = Int()
		var bits = UInt8()
		let maxv = 255 // 255 = 0xff = 11111111
		var converted: [UInt8] = []
		for d in data {
			guard (d >> 5) == 0 else {
				throw DecodeError.invalidCharacter
			}
			acc = (acc << 5) | Int(d)
			bits += 5

			while bits >= 8 {
				bits -= 8
				converted.append(UInt8(acc >> Int(bits) & maxv))
			}
		}

		let lastBits = UInt8(acc << (8 - bits) & maxv)
		guard bits < 5, lastBits == 0 else {
			throw DecodeError.invalidBits
		}

		return Data(converted)
	}

	internal enum DecodeError: Error {
		case invalidCharacter
		case invalidBits
	}
}
