import Foundation

// MARK: - SignalingServerMessage.Incoming.FromSignalingServerItself.ResponseForRequest
extension SignalingServerMessage.Incoming.FromSignalingServerItself {
	public enum ResponseForRequest: Sendable, Hashable, CustomStringConvertible {
		case success(SignalingServerMessage.Incoming.RequestId)
		case failure(RequestFailure)
	}
}

extension SignalingServerMessage.Incoming.FromSignalingServerItself.ResponseForRequest {
	internal var failure: RequestFailure? {
		switch self {
		case let .failure(value): return value
		case .success: return nil
		}
	}
}

extension SignalingServerMessage.Incoming.FromSignalingServerItself.ResponseForRequest {
	public var description: String {
		switch self {
		case let .failure(failure):
			return "failure(\(failure))"
		case let .success(requestId):
			return "success(requestId: \(requestId))"
		}
	}
}
