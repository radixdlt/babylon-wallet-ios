import Foundation

// MARK: - InternalDecodingFailure
/// Not to be confused with `DecodeError` case of `ErrorResponse` enum.
public enum InternalDecodingFailure: Swift.Error, Sendable, Equatable, Codable {
	case valueTypeDiscriminatorMismatch(expectedAnyOf: [ManifestASTValueKind], butGot: ManifestASTValueKind)
	case instructionTypeDiscriminatorMismatch(expected: InstructionKind, butGot: InstructionKind)
	case addressKindDiscriminatorMismatch(expected: Address.Kind, butGot: Address.Kind)
	case curvePrimitiveKindMismatch(expected: ECPrimitiveKind, butGot: String)
	case curveMismatch(expected: CurveDiscriminator, butGot: String)
	case parsingError
}

extension InternalDecodingFailure {
	static func valueTypeDiscriminatorMismatch(expected: ManifestASTValueKind, butGot: ManifestASTValueKind) -> Self {
		.valueTypeDiscriminatorMismatch(expectedAnyOf: [expected], butGot: butGot)
	}
}
