import Foundation

// MARK: - P2P.ToDapp.Response.Failure.Kind
public extension P2P.ToDapp.Response.Failure {
	enum Kind: Sendable, LocalizedError, Encodable, Hashable {
		public var rawValue: String {
			switch self {
			case .rejectedByUser: return "rejectedByUser"
			case let .error(error):
				return error.rawValue
			}
		}

		case rejectedByUser
		case error(Error)
		public func encode(to encoder: Encoder) throws {
			var singleValueContainer = encoder.singleValueContainer()
			try singleValueContainer.encode(rawValue)
		}

		public var errorDescription: String? {
			switch self {
			case .rejectedByUser:
				return "Rejected by user"
			case let .error(localizedError):
				return localizedError.errorDescription
			}
		}
	}
}
