import CryptoKit
import Foundation

// MARK: - Base58Check
/// A set of Base58Check coding methods.
///
/// ```
/// // Encode bytes to address
/// let address = Base58Check.encode([versionByte] + pubkeyHash)
///
/// // Decode address to bytes
/// guard let payload = Base58Check.decode(address) else {
///     // Invalid checksum or Base58 coding
///     throw SomeError()
/// }
/// let versionByte = payload[0]
/// let pubkeyHash = payload.dropFirst()
/// ```
public enum Base58Check {
	/// Encodes the data to Base58Check encoded string
	///
	/// Puts checksum bytes to the original data and then, encode the combined
	/// data to Base58 string.
	/// ```
	/// let address = Base58Check.encode([versionByte] + pubkeyHash)
	/// ```
	public static func encode(_ payload: Data) -> String {
		let checksum: Data = sha256sha256(payload).prefix(4)
		return Base58.encode(payload + checksum)
	}

	/// Decode the Base58 encoded String value to original payload
	///
	/// First validate if checksum bytes are the first 4 bytes of the sha256(sha256(payload)).
	/// If it's valid, returns the original payload.
	/// ```
	/// let payload = Base58Check.decode(base58checkText)
	/// ```
	public static func decode(_ string: String) -> Data? {
		guard let raw = Base58.decode(string) else {
			return nil
		}
		let checksum = raw.suffix(4)
		let payload = raw.dropLast(4)
		let checksumConfirm = sha256sha256(payload).prefix(4)
		guard checksum == checksumConfirm else {
			return nil
		}

		return payload
	}
}

func sha256(_ data: Data) -> Data {
	var sha256 = SHA256()
	sha256.update(data: data)
	return Data(sha256.finalize())
}

func sha256sha256(_ data: Data) -> Data {
	sha256(sha256(data))
}
