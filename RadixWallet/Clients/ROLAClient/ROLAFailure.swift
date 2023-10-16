
public enum ROLAFailure: Sendable, LocalizedError, Equatable {
	case wrongAccountType
	case unknownWebsite
	case radixJsonNotFound
	case radixJsonUnknownFileFormat
	case unknownDappDefinitionAddress

	public var errorDescription: String? {
		switch self {
		case .wrongAccountType:
			"Expected to find dapp definition account type"
		case .unknownWebsite:
			"Origin does not match any related website"
		case .radixJsonNotFound:
			"radix.json file is missing"
		case .radixJsonUnknownFileFormat:
			"radix.json file format mismatch"
		case .unknownDappDefinitionAddress:
			"dApp definition address does not match any well known definition address"
		}
	}

	public var errorKindAndMessage: (errorKind: P2P.Dapp.Response.WalletInteractionFailureResponse.ErrorType, message: String?) {
		switch self {
		case .wrongAccountType:
			(errorKind: .wrongAccountType, message: errorDescription)
		case .unknownWebsite:
			(errorKind: .unknownWebsite, message: errorDescription)
		case .radixJsonNotFound:
			(errorKind: .radixJsonNotFound, message: errorDescription)
		case .radixJsonUnknownFileFormat:
			(errorKind: .radixJsonUnknownFileFormat, message: errorDescription)
		case .unknownDappDefinitionAddress:
			(errorKind: .unknownDappDefinitionAddress, message: errorDescription)
		}
	}
}
