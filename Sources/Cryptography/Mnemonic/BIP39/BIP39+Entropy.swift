import Foundation
import Security

// MARK: - SecureBytesGenerator
private enum SecureBytesGenerator {}

private extension SecureBytesGenerator {
	enum Error: Swift.Error {
		case failed(code: OSStatus)
	}

	// https://developer.apple.com/documentation/security/1399291-secrandomcopybytes
	static func generate(byteCount count: Int) throws -> Data {
		var bytes = [UInt8](repeating: 0, count: count)
		let status: OSStatus = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
		guard status == errSecSuccess else {
			throw SecureBytesGenerator.Error.failed(code: status)
		}
		return Data(bytes)
	}
}

// MARK: - BIP39.Entropy
public extension BIP39 {
	struct Entropy: Equatable {
		public let data: Data
		public let wordCount: BIP39.WordCount

		public init(data: Data) throws {
			let byteCount = data.count
			guard let wordCount = BIP39.WordCount(byteCount: byteCount) else {
				throw Error.invalidByteCount(byteCount)
			}
			self.data = data
			self.wordCount = wordCount
		}

		public init(wordCount: BIP39.WordCount) throws {
			self.data = try SecureBytesGenerator.generate(byteCount: wordCount.byteCount)
			self.wordCount = wordCount
		}
	}
}

// MARK: - BIP39.Entropy.Error
public extension BIP39.Entropy {
	enum Error: Swift.Error, Equatable {
		case invalidByteCount(Int)
	}
}
