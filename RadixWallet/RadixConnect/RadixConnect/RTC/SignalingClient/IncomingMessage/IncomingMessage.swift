import WebRTC

// MARK: - SignalingClient.IncomingMessage
/// IncomingMessage from SignalingClient
extension SignalingClient {
	enum IncomingMessage: Sendable, Equatable {
		case fromSignalingServer(FromSignalingServer)
		case fromRemoteClient(RemoteData)
	}
}

extension SignalingClient.IncomingMessage {
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

extension SignalingClient.IncomingMessage.FromSignalingServer {
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

extension SignalingClient.IncomingMessage.RemoteData {
	/// Extract the Offer by attaching the remote client id.
	var offer: IdentifiedRTCOffer? {
		guard let offer = message.primitive.offer else {
			return nil
		}
		return .init(offer, id: remoteClientId)
	}

	/// Extract the Answer by attaching the remote client id.
	var answer: IdentifiedRTCAnswer? {
		guard let answer = message.primitive.answer else {
			return nil
		}
		return .init(answer, id: remoteClientId)
	}

	/// Extract the ICECandidate by attaching the remote client id.
	var iceCandidate: IdentifiedRTCICECandidate? {
		guard let candidate = message.primitive.iceCandidate else {
			return nil
		}
		return .init(candidate, id: remoteClientId)
	}
}

extension SignalingClient.IncomingMessage.FromSignalingServer.ResponseForRequest {
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
			.success(())
		case let .failure(.invalidMessageError(invalidMessageError)) where invalidMessageError.messageSentThatWasInvalid.requestId == needle:
			.failure(.invalidMessageError(invalidMessageError))
		case let .failure(.noRemoteClientToTalkTo(id)) where id == needle:
			.failure(.noRemoteClientToTalkTo(id))
		case let .failure(.validationError(validationError)) where validationError.requestId == needle:
			.failure(.validationError(validationError))
		default: nil
		}
	}

	var requestId: SignalingClient.ClientMessage.RequestID? {
		switch self {
		case let .success(id):
			id
		case let .failure(.noRemoteClientToTalkTo(id)):
			id
		case let .failure(.validationError(error)):
			error.requestId
		default:
			nil
		}
	}
}

extension SignalingClient.IncomingMessage.FromSignalingServer.Notification {
	var remoteClientDidConnect: Bool {
		switch self {
		case .remoteClientJustConnected,
		     .remoteClientIsAlreadyConnected:
			true
		case .remoteClientDisconnected:
			false
		}
	}

	var remoteClientId: RemoteClientID {
		switch self {
		case let .remoteClientDisconnected(id),
		     let .remoteClientIsAlreadyConnected(id),
		     let .remoteClientJustConnected(id):
			id
		}
	}
}
