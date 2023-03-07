import Prelude
import RadixConnectModels

// MARK: - SignalingClient.IncommingMessage
/// IncommingMessage from SignalingClient
extension SignalingClient {
	enum IncommingMessage: Sendable, Equatable {
		case fromSignalingServer(FromSignalingServer)
		case fromRemoteClient(RemoteData)
	}
}

extension SignalingClient.IncommingMessage {
	/// Received from SignalingServer itself
	enum FromSignalingServer: Sendable, Equatable {
		case notification(Notification)
		case responseForRequest(ResponseForRequest)
	}

	/// Received from Remote client itself
	struct RemoteData: Equatable, Sendable {
		/// The id of the remote client which sent the message.
		/// This field is actualy set by the SignalingServer, it is never configured by the client.
		let remoteClientId: RemoteClientID
		let message: SignalingClient.ClientMessage
	}

	var fromSignalingServer: FromSignalingServer? {
		guard case let .fromSignalingServer(value) = self else {
			return nil
		}
		return value
	}

	var fromRemoteClient: RemoteData? {
		guard case let .fromRemoteClient(value) = self else {
			return nil
		}
		return value
	}
}

extension SignalingClient.IncommingMessage.FromSignalingServer {
	/// Remote client status notifications
	enum Notification: Sendable, Equatable {
		case remoteClientJustConnected(RemoteClientID)
		case remoteClientDisconnected(RemoteClientID)
		case remoteClientIsAlreadyConnected(RemoteClientID)
	}

	enum ResponseForRequest: Sendable, Equatable {
		case success(SignalingClient.ClientMessage.RequestID)
		case failure(RequestFailure)
	}

	var responseForRequest: ResponseForRequest? {
		guard case let .responseForRequest(value) = self else {
			return nil
		}
		return value
	}

	var notification: Notification? {
		guard case let .notification(value) = self else {
			return nil
		}
		return value
	}
}

extension SignalingClient.IncommingMessage.RemoteData {
	/// Extract the Offer by attaching the remote client id.
	var offer: IdentifiedPrimitive<RTCPrimitive.Offer>? {
		guard let offer = message.primitive.offer else {
			return nil
		}
		return .init(content: offer, id: remoteClientId)
	}

	/// Extract the Answer by attaching the remote client id.
	var answer: IdentifiedPrimitive<RTCPrimitive.Answer>? {
		guard let answer = message.primitive.answer else {
			return nil
		}
		return .init(content: answer, id: remoteClientId)
	}

	/// Extract the ICECandidate by attaching the remote client id.
	var iceCandidate: IdentifiedPrimitive<RTCPrimitive.ICECandidate>? {
		guard let candidate = message.primitive.iceCandidate else {
			return nil
		}
		return .init(content: candidate, id: remoteClientId)
	}
}

extension SignalingClient.IncommingMessage.FromSignalingServer.ResponseForRequest {
	enum RequestFailure: Sendable, Equatable, Error {
		case noRemoteClientToTalkTo(SignalingClient.ClientMessage.RequestID)
		case validationError(ValidationError)
		case invalidMessageError(InvalidMessageError)
	}

	struct ValidationError: Sendable, Equatable {
		public let reason: JSONValue
		public let requestId: SignalingClient.ClientMessage.RequestID
	}

	struct InvalidMessageError: Sendable, Equatable {
		public let reason: JSONValue
		public let messageSentThatWasInvalid: SignalingClient.ClientMessage
	}

	func resultOfRequest(id needle: SignalingClient.ClientMessage.RequestID) -> Result<Void, RequestFailure>? {
		switch self {
		case let .success(id) where id == needle:
			return .success(())
		case let .failure(.invalidMessageError(invalidMessageError)) where invalidMessageError.messageSentThatWasInvalid.requestId == needle:
			return .failure(.invalidMessageError(invalidMessageError))
		case let .failure(.noRemoteClientToTalkTo(id)) where id == needle:
			return .failure(.noRemoteClientToTalkTo(id))
		case let .failure(.validationError(validationError)) where validationError.requestId == needle:
			return .failure(.validationError(validationError))
		default: return nil
		}
	}

	var requestId: SignalingClient.ClientMessage.RequestID? {
		switch self {
		case let .success(id):
			return id
		case let .failure(.noRemoteClientToTalkTo(id)):
			return id
		case let .failure(.validationError(error)):
			return error.requestId
		default:
			return nil
		}
	}
}

extension SignalingClient.IncommingMessage.FromSignalingServer.Notification {
	var remoteClientDidConnect: Bool {
		switch self {
		case .remoteClientJustConnected,
		     .remoteClientIsAlreadyConnected:
			return true
		case .remoteClientDisconnected:
			return false
		}
	}

	var remoteClientId: RemoteClientID {
		switch self {
		case let .remoteClientDisconnected(id),
		     let .remoteClientIsAlreadyConnected(id),
		     let .remoteClientJustConnected(id):
			return id
		}
	}
}
