import Foundation

// MARK: - BIP39.Error
public extension BIP39 {
	enum Error: Swift.Error {
		//        case randomBytesError
		//        case unsupportedByteCountOfEntropy(got: Int)
		case validationError(ValidationError)
	}
}

// MARK: - BIP39.Error.ValidationError
public extension BIP39.Error {
	enum ValidationError: Swift.Error {
		//        case badWordCount(expectedAnyOf: [Int], butGot: Int)
		case wordNotInList(String, language: BIP39.Language)
		//        case unableToDeriveLanguageFrom(words: [String])
		case checksumMismatch
	}
}
