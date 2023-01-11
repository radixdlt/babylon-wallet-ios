import Foundation

// MARK: - InternalDecodingFailure
/// Not to be confused with `DecodeError` case of `ErrorResponse` enum.
public enum InternalDecodingFailure: Swift.Error, Sendable, Equatable, Codable {
	case valueTypeDiscriminatorMismatch(expectedAnyOf: [ValueKind], butGot: ValueKind)
	case instructionTypeDiscriminatorMismatch(expected: InstructionKind, butGot: InstructionKind)
	case errorKindMismatch(expected: ErrorKind, butGot: ErrorKind)
	case parsingError
}

extension InternalDecodingFailure {
	static func valueTypeDiscriminatorMismatch(expected: ValueKind, butGot: ValueKind) -> Self {
		.valueTypeDiscriminatorMismatch(expectedAnyOf: [expected], butGot: butGot)
	}
}
