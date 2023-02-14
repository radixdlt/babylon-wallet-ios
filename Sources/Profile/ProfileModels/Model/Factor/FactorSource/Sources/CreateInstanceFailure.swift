import Prelude

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

extension CreateFactorInstanceFailure {
	public var customDumpDescription: String {
		_description
	}

	public var description: String {
		_description
	}

	public var _description: String {
		switch self {
		case let .expectedInputType(expectedType, unexpectedInput): return "CreateFactorInstanceFailure.expectedInputType(\(expectedType), butGot: \(unexpectedInput))"
		}
	}
}

// MARK: - PrivateKeyRequired
public struct PrivateKeyRequired: Swift.Error {}

// MARK: - IncorrectKeyNotMatchingFactorSourceID
public struct IncorrectKeyNotMatchingFactorSourceID: Swift.Error {}
