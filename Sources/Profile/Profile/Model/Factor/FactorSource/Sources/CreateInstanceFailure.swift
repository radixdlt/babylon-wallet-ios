import CustomDump
import Foundation

// MARK: - CreateFactorInstanceFailure
public enum CreateFactorInstanceFailure:
	Swift.Error,
	Sendable,
	Hashable,
	Codable,
	CustomStringConvertible,
	CustomDumpStringConvertible
{
	case expectedInputType(String, gotGot: String)
}

public extension CreateFactorInstanceFailure {
	var customDumpDescription: String {
		_description
	}

	var description: String {
		_description
	}

	var _description: String {
		switch self {
		case let .expectedInputType(expectedType, unexpectedInput): return "CreateFactorInstanceFailure.expectedInputType(\(expectedType), butGot: \(unexpectedInput))"
		}
	}
}

// MARK: - PrivateKeyRequired
public struct PrivateKeyRequired: Swift.Error {}

// MARK: - IncorrectKeyNotMatchingFactorSourceID
public struct IncorrectKeyNotMatchingFactorSourceID: Swift.Error {}
