import EngineToolkit
import Foundation

extension RadixEngineToolkitError: LocalizedError {
	static let errorPrefix = "Engine Toolkit Error: "
	public var errorDescription: String? {
		let errorMessage = switch self {
		case let .InvalidLength(expected, actual, data):
			"InvalidLength - expected: \(expected), actual: \(actual)"
		case let .FailedToExtractNetwork(address):
			"FailedToExtractNetwork: \(address)"
		case let .Bech32DecodeError(error):
			"Bech32DecodeError - \(error)"
		case let .ParseError(typeName, error):
			"ParseError - type: \(typeName), error: \(error)"
		case let .NonFungibleContentValidationError(error):
			"NonFungibleContentValidationError - \(error)"
		case let .EntityTypeMismatchError(expected, actual):
			"EntityTypeMismatchError - expected: \(expected), actual: \(actual)"
		case let .DerivationError(error):
			"DerivationError - \(error)"
		case .InvalidPublicKey:
			"InvalidPublicKey"
		case let .CompileError(error):
			"CompileError - \(error)"
		case let .DecompileError(error):
			"DecompileError - \(error)"
		case let .PrepareError(error):
			"PrepareError - \(error)"
		case let .EncodeError(error):
			"EncodeError - \(error)"
		case let .DecodeError(error):
			"DecodeError - \(error)"
		case let .TransactionValidationFailed(error):
			"TransactionValidationFailed - \(error)"
		case let .ExecutionModuleError(error):
			"ExecutionModuleError - \(error)"
		case let .ManifestSborError(error):
			"ManifestSborError - \(error)"
		case let .ScryptoSborError(error):
			"ScryptoSborError - \(error)"
		case let .TypedNativeEventError(error):
			"TypedNativeEventError - \(error)"
		case .FailedToDecodeTransactionHash:
			"FailedToDecodeTransactionHash"
		case let .ManifestBuilderNameRecordError(error):
			"ManifestBuilderNameRecordError - \(error)"
		case let .ManifestModificationError(error):
			"ManifestModificationError - \(error)"
		case let .InvalidEntityTypeIdError(error):
			"InvalidEntityTypeIdError - \(error)"
		case .DecimalError:
			"DecimalError"
		case let .SignerError(error):
			"SignerError - \(error)"
		case .InvalidReceipt:
			"InvalidReceipt"
		}

		return Self.errorPrefix + errorMessage
	}
}
