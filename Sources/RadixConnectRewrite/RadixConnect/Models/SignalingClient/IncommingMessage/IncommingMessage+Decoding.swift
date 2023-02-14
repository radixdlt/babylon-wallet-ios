import Foundation

// MARK: - IncommingMessage.ResponseType
extension IncommingMessage {
	enum ResponseType: String, Decodable, Sendable {
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
		case fromRemoteClient = "remoteData"
	}
}

// MARK: - IncommingMessage + Decodable
extension IncommingMessage: Decodable {
	enum CodingKeys: String, CodingKey {
		case responseType = "info", requestId, error,
		     source = "target", message = "data", remoteClientId
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let responseType = try container.decode(ResponseType.self, forKey: .responseType)

		switch responseType {
		case .fromRemoteClient:
			self = try .fromRemoteClient(container.decode(ClientMessage.self, forKey: .message))

		case .remoteClientJustConnected:
			let clientId = try container.decode(ClientID.self, forKey: .remoteClientId)
			self = .fromSignalingServer(.notification(.remoteClientJustConnected(clientId)))
		case .remoteClientIsAlreadyConnected:
			let clientId = try container.decode(ClientID.self, forKey: .remoteClientId)
			self = .fromSignalingServer(.notification(.remoteClientIsAlreadyConnected(clientId)))
		case .remoteClientDisconnected:
			let clientId = try container.decode(ClientID.self, forKey: .remoteClientId)
			self = .fromSignalingServer(.notification(.remoteClientDisconnected(clientId)))

		case .missingRemoteClientError:
			let requestId = try container.decode(RequestID.self, forKey: .requestId)

			self = .fromSignalingServer(
				.responseForRequest(
					.failure(
						.noRemoteClientToTalkTo(requestId)
					)
				)
			)

		case .validationError:
			let error = try container.decode(JSONValue.self, forKey: .error)
			let requestId = try container.decode(RequestID.self, forKey: .requestId)
			self = .fromSignalingServer(
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
			let message = try container.decode(ClientMessage.self, forKey: .message)
			self = .fromSignalingServer(
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
			let requestId = try container.decode(RequestID.self, forKey: .requestId)
			self = .fromSignalingServer(.responseForRequest(.success(requestId)))
		}
	}
}
