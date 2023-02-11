import Foundation
import P2PModels

// MARK: - SignalingServerMessage.Incoming.FromSignalingServerItself.ResponseForRequest.RequestFailure.InvalidMessageError
extension SignalingServerMessage.Incoming.FromSignalingServerItself.ResponseForRequest.RequestFailure {
	public struct InvalidMessageError: Swift.Error, Sendable, Hashable, CustomStringConvertible {
		public let reason: JSONValue
		public let messageSentThatWasInvalid: RPCMessage
	}
}

extension SignalingServerMessage.Incoming.FromSignalingServerItself.ResponseForRequest.RequestFailure.InvalidMessageError {
	public var description: String {
		"reason: \(String(describing: reason)), requestIdOfInvalidMsg: \(messageSentThatWasInvalid.requestId)"
	}
}
