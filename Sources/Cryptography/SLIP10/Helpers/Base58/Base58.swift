import Foundation

// MARK: - _Base58
private struct _Base58: Encoding {
	static let baseAlphabets = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
	static var zeroAlphabet: Character = "1"
	static var base: Int = 58

	static func sizeFromByte(size: Int) -> Int {
		size * 138 / 100 + 1
	}

	static func sizeFromBase(size: Int) -> Int {
		size * 733 / 1000 + 1
	}
}

// MARK: - Base58
public enum Base58 {
	public static func encode(_ bytes: Data) -> String {
		_Base58.encode(bytes)
	}

	public static func decode(_ string: String) -> Data? {
		_Base58.decode(string)
	}
}
