import Foundation

// MARK: - SignalingServerMessage.Incoming.FromSignalingServerItself.ResponseForRequest.RequestFailure
public extension SignalingServerMessage.Incoming.FromSignalingServerItself.ResponseForRequest {
	enum RequestFailure: Sendable, Hashable, CustomStringConvertible {
		case noRemoteClientToTalkTo(SignalingServerMessage.Incoming.RequestId)
		case validationError(ValidationError)
		case invalidMessageError(InvalidMessageError)
	}
}

public extension SignalingServerMessage.Incoming.FromSignalingServerItself.ResponseForRequest.RequestFailure {
	var description: String {
		switch self {
		case let .invalidMessageError(error):
			return "invalidMessageError(\(error))"
		case let .validationError(error):
			return "validationError(\(error))"
		case let .noRemoteClientToTalkTo(requestId):
			return "noRemoteClientToTalkTo(requestId: \(requestId))"
		}
	}
}

internal extension SignalingServerMessage.Incoming.FromSignalingServerItself.ResponseForRequest.RequestFailure {
	var invalidMessageError: InvalidMessageError? {
		switch self {
		case let .invalidMessageError(value): return value
		case .noRemoteClientToTalkTo, .validationError: return nil
		}
	}

	var validationError: ValidationError? {
		switch self {
		case let .validationError(value): return value
		case .noRemoteClientToTalkTo, .invalidMessageError:
			return nil
		}
	}
}
