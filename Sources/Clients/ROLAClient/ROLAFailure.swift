import ClientPrelude

public enum ROLAFailure: Sendable, LocalizedError, Equatable {
	case wrongAccountType
	case unknownWebsite
	case invalidOriginURL
	case radixJsonNotFound
	case radixJsonUnknownFileFormat
	case unknownDappDefinitionAddress

	public var errorDescription: String? {
		switch self {
		case .wrongAccountType:
			return "Expected to find dapp definition account type"
		case .unknownWebsite:
			return "Origin does not match any related website"
		case .invalidOriginURL:
			return "Invalid origin URL"
		case .radixJsonNotFound:
			return "radix.json file is missing"
		case .radixJsonUnknownFileFormat:
			return "radix.json file format mismatch"
		case .unknownDappDefinitionAddress:
			return "dApp definition address does not match any well known definition address"
		}
	}

	public var errorKindAndMessage: (errorKind: P2P.Dapp.Response.WalletInteractionFailureResponse.ErrorType, message: String?) {
		switch self {
		case .wrongAccountType:
			return (errorKind: .wrongAccountType, message: errorDescription)
		case .unknownWebsite:
			return (errorKind: .unknownWebsite, message: errorDescription)
		case .invalidOriginURL:
			return (errorKind: .invalidOriginURL, message: errorDescription)
		case .radixJsonNotFound:
			return (errorKind: .radixJsonNotFound, message: errorDescription)
		case .radixJsonUnknownFileFormat:
			return (errorKind: .radixJsonUnknownFileFormat, message: errorDescription)
		case .unknownDappDefinitionAddress:
			return (errorKind: .unknownDappDefinitionAddress, message: errorDescription)
		}
	}
}
