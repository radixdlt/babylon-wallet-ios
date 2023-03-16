import Prelude
import XCTest

// MARK: - ValidationTests
final class ValidationTests: XCTestCase {
	func test() {
		struct Person {
//			@Sanitized
//			@Validation<String, NameValidationError>() var name
			@Validation(.name) var name: String?
//			@Validation(NameValidationError.self) var name
		}

		let sut = Person()
	}
}

extension [ValidationRuleOf<NameValidationError>] {
	static let name = NameValidationError.rules
}

// MARK: - NameValidationError
public enum NameValidationError: ValidationError, LocalizedError {
	case blank
	case tooShort
	case tooLong
	case invalidCharacters

	public var condition: (String) -> Bool {
		switch self {
		case .blank:
			return \.isBlank
		case .tooShort:
			return { $0.count <= 2 }
		case .tooLong:
			return { $0.count > 15 }
		case .invalidCharacters:
			return { $0.rangeOfCharacter(from: .symbols) != nil }
		}
	}

	public var errorDescription: String? {
		switch self {
		case .blank:
			return "First name cannot be blank"
		case .tooShort:
			return "First name is too short"
		case .tooLong:
			return "First name is too long"
		case .invalidCharacters:
			return "First name contains invalid characters"
		}
	}
}
