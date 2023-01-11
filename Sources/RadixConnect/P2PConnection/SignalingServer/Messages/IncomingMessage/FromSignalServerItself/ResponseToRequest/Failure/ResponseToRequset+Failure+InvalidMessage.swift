import Foundation
import P2PModels

// MARK: - SignalingServerMessage.Incoming.FromSignalingServerItself.ResponseForRequest.RequestFailure.InvalidMessageError
public extension SignalingServerMessage.Incoming.FromSignalingServerItself.ResponseForRequest.RequestFailure {
	struct InvalidMessageError: Swift.Error, Sendable, Hashable, CustomStringConvertible {
		public let reason: JSONValue
		public let messageSentThatWasInvalid: RPCMessage
	}
}

public extension SignalingServerMessage.Incoming.FromSignalingServerItself.ResponseForRequest.RequestFailure.InvalidMessageError {
	var description: String {
		"reason: \(String(describing: reason)), requestIdOfInvalidMsg: \(messageSentThatWasInvalid.requestId)"
	}
}
