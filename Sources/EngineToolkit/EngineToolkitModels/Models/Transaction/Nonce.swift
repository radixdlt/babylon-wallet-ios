import Prelude

extension Nonce {
	public static func secureRandom() -> Self {
		let byteCount = RawValue.bitWidth / 8
		var data = Data(repeating: 0, count: byteCount)
		data.withUnsafeMutableBytes {
			assert($0.count == byteCount)
			$0.initializeWithRandomBytes(count: byteCount)
		}
		let rawValue = data.withUnsafeBytes { $0.load(as: RawValue.self) }
		return Self(rawValue: rawValue)
	}
}

// MARK: - NonceTag
public enum NonceTag: Sendable {}

/// Secure random unique 8 bytes.
public typealias Nonce = Tagged<NonceTag, UInt64>
