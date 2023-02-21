import Foundation
import P2PModels

// MARK: - SignalingServerMessage.Incoming.FromSignalingServerItself.ResponseForRequest.RequestFailure.ValidationError
extension SignalingServerMessage.Incoming.FromSignalingServerItself.ResponseForRequest.RequestFailure {
	public struct ValidationError: Swift.Error, Sendable, Hashable, CustomStringConvertible {
		public let reason: JSONValue
		public let requestId: SignalingServerMessage.Incoming.RequestId
	}
}

extension SignalingServerMessage.Incoming.FromSignalingServerItself.ResponseForRequest.RequestFailure.ValidationError {
	public var description: String {
		"reason: \(String(describing: reason)), requestId: \(requestId)"
	}
}
