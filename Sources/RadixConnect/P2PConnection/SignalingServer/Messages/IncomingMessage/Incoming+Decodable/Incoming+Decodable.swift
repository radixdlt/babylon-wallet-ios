import Foundation
import Prelude

// MARK: - SignalingServerMessage.Incoming.ResponseType
extension SignalingServerMessage.Incoming {
	fileprivate enum ResponseType: String, Codable, Sendable, Hashable {
		// MARK: ResponseToRequest

		/// Confirmation sent to us by the signaling server informing us that an RPC message sent by us was accepted by the signaling server, but necessarily received by any remote client yet. If we get this, it means that we did not get `missingRemoteClientError`, and these two events (messages) are mutually exclusive, i.e. the signaling server knows that it can dispatch our sent message to a remote client.
		case success = "confirmation"
		/// Signaling server is unable to dispatch our sent message to any other client, because no other client is connected to it.
		case missingRemoteClientError
		/// Our message was correct JSON but semantically incorrect, i.e. contains bad values.
		case invalidMessageError
		/// We are not sending correct JSON - this is bad!
		case validationError

		// MARK: NOTIFICATIONS

		/// A remote client we were indirectly connected to via the signaling server just disconnected from the signaling server.
		/// We SHOULD not continue sending any data if an WebRTC connection has not yet been established.
		case remoteClientDisconnected

		/// A remote client just connected to the signaling server, meaning we connect first, we should not have sent any messages so far if we haven't already seed a `remoteClientIsAlreadyConnected` event first.
		case remoteClientJustConnected

		/// A remote client is already connected to the signaling sever, meaning it connected first and we second. We are ready to send messages to the signaling server since we have a receiving remote client.
		case remoteClientIsAlreadyConnected

		// MARK: From Remote
		/// RPC message sent by the remote client originally, dispatch to us through the signaling server
		case fromRemoteClientOriginally = "remoteData"
	}
}

extension SignalingServerMessage.Incoming {
	public enum CodingKeys: String, CodingKey {
		case responseType = "info", requestId, error, source = "target", message = "data"
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let responseType = try container.decode(ResponseType.self, forKey: .responseType)

		switch responseType {
		case .fromRemoteClientOriginally:
			self = try .fromRemoteClientOriginally(container.decode(FromRemoteClientOriginally.self, forKey: .message))

		case .remoteClientJustConnected:
			self = .fromSignalingServerItself(.notification(.remoteClientJustConnected))
		case .remoteClientIsAlreadyConnected:
			self = .fromSignalingServerItself(.notification(.remoteClientIsAlreadyConnected))
		case .remoteClientDisconnected:
			self = .fromSignalingServerItself(.notification(.remoteClientDisconnected))

		case .missingRemoteClientError:
			let requestId = try container.decode(RequestId.self, forKey: .requestId)

			self = .fromSignalingServerItself(
				.responseForRequest(
					.failure(
						.noRemoteClientToTalkTo(requestId)
					)
				)
			)

		case .validationError:
			let error = try container.decode(JSONValue.self, forKey: .error)
			let requestId = try container.decode(RequestId.self, forKey: .requestId)
			self = .fromSignalingServerItself(
				.responseForRequest(
					.failure(
						.validationError(
							.init(
								reason: error,
								requestId: requestId
							)
						)
					)
				)
			)
		case .invalidMessageError:
			let error = try container.decode(JSONValue.self, forKey: .error)
			let message = try container.decode(FromRemoteClientOriginally.self, forKey: .message)
			self = .fromSignalingServerItself(
				.responseForRequest(
					.failure(
						.invalidMessageError(
							.init(
								reason: error,
								messageSentThatWasInvalid: message
							)
						)
					)
				)
			)
		case .success:
			let requestId = try container.decode(RequestId.self, forKey: .requestId)
			self = .fromSignalingServerItself(.responseForRequest(.success(requestId)))
		}
	}
}

#if DEBUG
extension SignalingServerMessage.Incoming: Encodable {}
extension SignalingServerMessage.Incoming {
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		switch self {
		case let .fromSignalingServerItself(fromSignalingServerItself):
			switch fromSignalingServerItself {
			case let .notification(notification):
				switch notification {
				case .remoteClientJustConnected:
					try container.encode(ResponseType.remoteClientJustConnected, forKey: .responseType)
				case .remoteClientDisconnected:
					try container.encode(ResponseType.remoteClientDisconnected, forKey: .responseType)
				case .remoteClientIsAlreadyConnected:
					try container.encode(ResponseType.remoteClientIsAlreadyConnected, forKey: .responseType)
				}
			case let .responseForRequest(responseForRequest):
				switch responseForRequest {
				case let .failure(failure):
					switch failure {
					case let .invalidMessageError(error):
						try container.encode(ResponseType.invalidMessageError, forKey: .responseType)
						try container.encode(error.messageSentThatWasInvalid, forKey: .message)
					case let .noRemoteClientToTalkTo(requestId):
						try container.encode(ResponseType.missingRemoteClientError, forKey: .responseType)
						try container.encode(requestId, forKey: .requestId)
					case let .validationError(error):
						try container.encode(ResponseType.validationError, forKey: .responseType)
						try container.encode(error.requestId, forKey: .requestId)
						try container.encode(error.reason.description, forKey: .error)
					}
				case let .success(requestId):
					try container.encode(ResponseType.success, forKey: .responseType)
					try container.encode(requestId, forKey: .requestId)
				}
			}
		case let .fromRemoteClientOriginally(fromRemoteClientOriginally):
			try container.encode(ResponseType.fromRemoteClientOriginally, forKey: .responseType)
			try container.encode(fromRemoteClientOriginally, forKey: .message)
		}
	}
}
#endif // DEBUG
