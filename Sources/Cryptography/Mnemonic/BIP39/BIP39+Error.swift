import Foundation

// MARK: - BIP39.Error
extension BIP39 {
	public enum Error: Swift.Error {
		//        case randomBytesError
		//        case unsupportedByteCountOfEntropy(got: Int)
		case validationError(ValidationError)
	}
}

// MARK: - BIP39.Error.ValidationError
extension BIP39.Error {
	public enum ValidationError: Swift.Error {
		//        case badWordCount(expectedAnyOf: [Int], butGot: Int)
		case wordNotInList(String, language: BIP39.Language)
		//        case unableToDeriveLanguageFrom(words: [String])
		case checksumMismatch
	}
}
