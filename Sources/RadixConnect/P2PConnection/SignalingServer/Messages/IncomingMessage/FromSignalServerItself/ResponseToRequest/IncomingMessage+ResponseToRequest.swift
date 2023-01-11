import Foundation

// MARK: - SignalingServerMessage.Incoming.FromSignalingServerItself.ResponseForRequest
public extension SignalingServerMessage.Incoming.FromSignalingServerItself {
	enum ResponseForRequest: Sendable, Hashable, CustomStringConvertible {
		case success(SignalingServerMessage.Incoming.RequestId)
		case failure(RequestFailure)
	}
}

internal extension SignalingServerMessage.Incoming.FromSignalingServerItself.ResponseForRequest {
	var failure: RequestFailure? {
		switch self {
		case let .failure(value): return value
		case .success: return nil
		}
	}
}

public extension SignalingServerMessage.Incoming.FromSignalingServerItself.ResponseForRequest {
	var description: String {
		switch self {
		case let .failure(failure):
			return "failure(\(failure))"
		case let .success(requestId):
			return "success(requestId: \(requestId))"
		}
	}
}
