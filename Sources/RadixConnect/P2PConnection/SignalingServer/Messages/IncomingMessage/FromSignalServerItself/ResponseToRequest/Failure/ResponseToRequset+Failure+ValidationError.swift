import Foundation
import P2PModels

// MARK: - SignalingServerMessage.Incoming.FromSignalingServerItself.ResponseForRequest.RequestFailure.ValidationError
public extension SignalingServerMessage.Incoming.FromSignalingServerItself.ResponseForRequest.RequestFailure {
	struct ValidationError: Swift.Error, Sendable, Hashable, CustomStringConvertible {
		public let reason: JSONValue
		public let requestId: SignalingServerMessage.Incoming.RequestId
	}
}

public extension SignalingServerMessage.Incoming.FromSignalingServerItself.ResponseForRequest.RequestFailure.ValidationError {
	var description: String {
		"reason: \(String(describing: reason)), requestId: \(requestId)"
	}
}
