import RadixConnectModels

// MARK: - IncommingMessage
enum IncommingMessage: Sendable, Equatable {
	enum FromSignalingServer: Sendable, Equatable {
		case notification(Notification)
		case responseForRequest(ResponseForRequest)
	}

	case fromSignalingServer(FromSignalingServer)
	case fromRemoteClient(RemoteData)
}

extension IncommingMessage {
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

extension IncommingMessage.FromSignalingServer {
	enum Notification: Sendable, Equatable {
		case remoteClientJustConnected(RemoteClientID)
		case remoteClientDisconnected(RemoteClientID)
		case remoteClientIsAlreadyConnected(RemoteClientID)
	}

	enum ResponseForRequest: Sendable, Equatable {
		case success(RequestID)
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

extension IncommingMessage.FromSignalingServer.ResponseForRequest {
	enum RequestFailure: Sendable, Equatable, Error {
		case noRemoteClientToTalkTo(RequestID)
		case validationError(ValidationError)
		case invalidMessageError(InvalidMessageError)
	}

	struct ValidationError: Sendable, Equatable {
		public let reason: JSONValue
		public let requestId: RequestID
	}

	struct InvalidMessageError: Sendable, Equatable {
		public let reason: JSONValue
		public let messageSentThatWasInvalid: ClientMessage
	}
}

extension IncommingMessage.FromSignalingServer.ResponseForRequest {
	func resultOfRequest(id needle: RequestID) -> Result<Void, RequestFailure>? {
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

	var requestId: RequestID? {
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

extension IncommingMessage.FromSignalingServer.Notification {
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
