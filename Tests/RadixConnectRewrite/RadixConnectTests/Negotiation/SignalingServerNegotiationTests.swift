@testable import RadixConnect
import TestingPrelude

// MARK: - SignalingServerNegotiationTests
@MainActor
final class SignalingServerNegotiationTests: TestCase {
	// Static config
	static let connectionID = try! SignalingServerConnectionID(.init(.deadbeef32Bytes))
	static let encryptionKey = try! EncryptionKey(rawValue: .init(data: .deadbeef32Bytes))
        lazy var jsonDecoder: JSONDecoder = {
                let decoder = JSONDecoder()
                decoder.userInfo[.clientMessageEncryptonKey] = Self.encryptionKey
                return decoder
        }()

        lazy var jsonEncoder: JSONEncoder = {
                let encoder = JSONEncoder()
                encoder.userInfo[.clientMessageEncryptonKey] = Self.encryptionKey
                return encoder
        }()

	// Shared clients
	let dataChannelClient = DataChannelClient(dataChannel: DataChannelMock(), delegate: DataChannelDelegateMock())
	let webSocketClient = MockWebSocketClient()
	lazy var signalingClient = SignalingClient(encryptionKey: Self.encryptionKey,
	                                           webSocketClient: webSocketClient,
	                                           connectionID: Self.connectionID)

	func test_makePeerConnection_happyFlow() async throws {
		let remoteClientID = ClientID.any
		let (client, peerConnection, delegate) = makePeerConnectionClient(remoteClientID)
		let peerConnectionFactory = MockPeerConnectionFactory(clients: [client])
		let conenctionBuilder = PeerConnectionBuilder(signalingServerClient: signalingClient, factory: peerConnectionFactory)

		let peerConnectionTask = Task {
			await conenctionBuilder.peerConnections.prefix(1).collect()
		}

		// Negotiate the PeerConnection
		try await performNegotiation(forClient: remoteClientID, peerConnection: peerConnection, peerConnectionDelegate: delegate)

		// Await for PeerConnection to be estblished
		let result = await peerConnectionTask.value.first!
		XCTAssertEqual(result.map(\.id), .success(remoteClientID))
	}

	func test_makePeerConnection_parallelNegotiation() async throws {
		// Configure 4 peer connections to be negotiated in parallel
		let remoteClientId2 = ClientID(rawValue: UUID().uuidString)
		let remoteClientId3 = ClientID(rawValue: UUID().uuidString)
		let remoteClientId1 = ClientID(rawValue: UUID().uuidString)
		let remoteClientId4 = ClientID(rawValue: UUID().uuidString)

		let (client1, peerConnection1, delegate1) = makePeerConnectionClient(remoteClientId1)
		let (client2, peerConnection2, delegate2) = makePeerConnectionClient(remoteClientId2)
		let (client3, peerConnection3, delegate3) = makePeerConnectionClient(remoteClientId3)
		let (client4, peerConnection4, delegate4) = makePeerConnectionClient(remoteClientId4)
		let peerConnectionFactory = MockPeerConnectionFactory(clients: [client1, client2, client3, client4])
		let conenctionBuilder = PeerConnectionBuilder(signalingServerClient: signalingClient, factory: peerConnectionFactory)

		let peerConnectionTask = Task {
			// Await for 4 PeerConnection to be made
			await conenctionBuilder.peerConnections.prefix(4).collect()
		}

		// Trigger negotiations

		Task {
			try await performNegotiation(forClient: remoteClientId1, peerConnection: peerConnection1, peerConnectionDelegate: delegate1)
		}

		Task {
			try await performNegotiation(forClient: remoteClientId2, peerConnection: peerConnection2, peerConnectionDelegate: delegate2)
		}

		Task {
			try await performNegotiation(forClient: remoteClientId3, peerConnection: peerConnection3, peerConnectionDelegate: delegate3)
		}

		Task {
			try await performFailingNegotiation(forClient: remoteClientId4, peerConnection: peerConnection4, peerConnectionDelegate: delegate4)
		}

		// Assert that the result for all negotiations are returns

		/// We are interested only comparing the created `PeerConnectionClient.id`'s, or the failure
		let result: [ClientID: Result<ClientID, FailedToCreatePeerConnectionError>] = await peerConnectionTask
			.value
			.reduce(into: [:]) { partialResult, nextResult in
				switch nextResult {
				case let .success(peerConnection):
					partialResult[peerConnection.id] = .success(peerConnection.id)
				case let .failure(failure):
					partialResult[failure.remoteClientId] = .failure(failure)
				}
			}

		let expectedResults: [ClientID: Result<ClientID, FailedToCreatePeerConnectionError>] = [
			remoteClientId1: .success(remoteClientId1),
			remoteClientId2: .success(remoteClientId2),
			remoteClientId3: .success(remoteClientId3),
			remoteClientId4: .failure(FailedToCreatePeerConnectionError(remoteClientId: remoteClientId4, underlyingError: NSError(domain: "dom", code: 1))),
		]

		XCTAssertEqual(result, expectedResults)
	}

	func test_makePeerConnection_failedToSetRemoteDescriptionAfterOffer() async throws {
		let remoteClientId = ClientID.any
		let (client, peerConnection, delegate) = makePeerConnectionClient(remoteClientId)
		let peerConnectionFactory = MockPeerConnectionFactory(clients: [client])
		let conenctionBuilder = PeerConnectionBuilder(signalingServerClient: signalingClient, factory: peerConnectionFactory)

		let peerConnectionTask = Task {
			await conenctionBuilder.peerConnections.prefix(1).collect().first!
		}

		try webSocketClient.receiveIncommingMessage(
			makeClientMessage(.anyOffer(for: remoteClientId))
		)
		delegate.sendNegotiationNeededEvent()

		// Await set offer
		_ = await peerConnection.onRemoteOffer()
		peerConnection.completeSetRemoteOffer(with: .failure(NSError(domain: "dom", code: 1)))

		let result = await peerConnectionTask.value

		XCTAssertThrowsError(try result.get())
	}

	func test_makePeerConnection_failsToGenerateAnswer() async throws {
		let remoteClientId = ClientID.any
		let (client, peerConnection, delegate) = makePeerConnectionClient(remoteClientId)
		let peerConnectionFactory = MockPeerConnectionFactory(clients: [client])
		let conenctionBuilder = PeerConnectionBuilder(signalingServerClient: signalingClient, factory: peerConnectionFactory)

		let peerConnectionTask = Task {
			await conenctionBuilder.peerConnections.prefix(1).collect().first!
		}

		try await receiveRemoteOffer(.anyOffer(for: remoteClientId), peerConnection: peerConnection, peerConnectionDelegate: delegate)

		await peerConnection.onCreateLocalAnswer()
		peerConnection.completeCreateLocalAnswerRequest(with: .failure(NSError(domain: "dom", code: 1)))

		let result = await peerConnectionTask.value

		XCTAssertThrowsError(try result.get())
	}

	func test_makePeerConnection_failsToSendAnswerToRemote() async throws {
		let remoteClientId = ClientID.any
		let (client, peerConnection, delegate) = makePeerConnectionClient(remoteClientId)
		let peerConnectionFactory = MockPeerConnectionFactory(clients: [client])
		let conenctionBuilder = PeerConnectionBuilder(signalingServerClient: signalingClient, factory: peerConnectionFactory)

		let peerConnectionTask = Task {
			await conenctionBuilder.peerConnections.prefix(1).collect().first!
		}

		try await receiveRemoteOffer(.anyOffer(for: remoteClientId), peerConnection: peerConnection, peerConnectionDelegate: delegate)

		await peerConnection.onCreateLocalAnswer()
		peerConnection.completeCreateLocalAnswerRequest(with: .success(.any))

                let message = try await jsonDecoder.decode(ClientMessage.self, from: webSocketClient.onClientMessageSent())
		webSocketClient.respondToRequest(message: .failure(.noRemoteClientToTalkTo(.init(message.requestId.rawValue))))
		let result = await peerConnectionTask.value

		XCTAssertThrowsError(try result.get())
	}

	// MARK: - Private

	/// Performs the full successfull negotiation flow for the given remoteClientId
	private func performNegotiation(
		forClient remoteClientId: ClientID,
		peerConnection: MockPeerConnection,
		peerConnectionDelegate: MockPeerConnectionDelegate
	) async throws {
		// Receive incomming offer from remoteClientId
		try await receiveRemoteOffer(.anyOffer(for: remoteClientId), peerConnection: peerConnection, peerConnectionDelegate: peerConnectionDelegate)

		// Send answer
		try await createAndSendAnswer(.anyAnswer(for: remoteClientId), peerConnection: peerConnection)

		// Receive ICECandidate
		try await receiveICECandidate(.anyICECandidate(for: remoteClientId), peerConnection: peerConnection)

		// Send ICECandidate
		try await sendICECandidate(.anyICECandidate(for: remoteClientId), peerConnectionDelegate: peerConnectionDelegate)

		// When ICEConnection state is connected the negotiation is completed
		peerConnectionDelegate.sendICEConnectionStateEvent(.connected)
	}

	/// Performs a failing negotiation flow for the given remoteClientId
	private func performFailingNegotiation(forClient remoteClientId: ClientID,
	                                       peerConnection: MockPeerConnection,
	                                       peerConnectionDelegate: MockPeerConnectionDelegate) async throws
	{
		try webSocketClient.receiveIncommingMessage(
			makeClientMessage(.anyOffer(for: remoteClientId))
		)

		peerConnectionDelegate.sendNegotiationNeededEvent()

		// Await set offer
		_ = await peerConnection.onRemoteOffer()
		peerConnection.completeSetRemoteOffer(with: .failure(NSError(domain: "dom", code: 1)))
	}

	/// This function will trigger the negotiation flow for the given offer,
	/// as well it will assert that the Offer was properly set on the created PeerConnection.
	private func receiveRemoteOffer(_ primitive: IdentifiedPrimitive<RTCPrimitive>,
	                                peerConnection: MockPeerConnection,
	                                peerConnectionDelegate: MockPeerConnectionDelegate) async throws
	{
		// Receive the incomming offer
		try webSocketClient.receiveIncommingMessage(
			makeClientMessage(primitive)
		)

		// Before setting the Offer, the negotiation needed event has to occur
		peerConnectionDelegate.sendNegotiationNeededEvent()

		// Await for the remote offer to be configured on the peer connection
		let configuredOffer = await peerConnection.configuredRemoteOffer.prefix(1).collect().first!

		// Assert that the configured offer does amtch the incomming offer
                XCTAssertEqual(configuredOffer, primitive.content.offer)

		// Complete the set remote offer action on peerConnection, thus allowing the negotiation to flow further
		peerConnection.completeSetRemoteOffer(with: .success(()))
	}

	/// Trigger a `receiveICECandidate` event, as well assert that the received ICECanddiate is properly set on the PeerConnection
	private func receiveICECandidate(_ primitive: IdentifiedPrimitive<RTCPrimitive>, peerConnection: MockPeerConnection) async throws {
		// Receive the incomming ICECandidate
		try webSocketClient.receiveIncommingMessage(
			makeClientMessage(primitive)
		)

		// Await for the ICECandidate to be configured on peerConnection
                let configuredICECandidate = await peerConnection.configuredICECandidate.prefix(1).collect().first!

		// Assert that the configured ICECandidate does match the incomming ICECanddiate
                XCTAssertEqual(configuredICECandidate, primitive.content.iceCandidate)

		// Complete the add ICECandidate action on PeerConnection
		peerConnection.completeAddICECandidate(with: .success(()))
	}

	/// Trigger the `generated local ICECandidate` event, as well assert that the generated ICECandidate is sent throught he WebSocket to the proper client
	private func sendICECandidate(_ primitive: IdentifiedPrimitive<RTCPrimitive>, peerConnectionDelegate: MockPeerConnectionDelegate) async throws {
		// Generate local ICECandidate
                peerConnectionDelegate.generateICECandiddate(primitive.content.iceCandidate!)

		// Assert that the generated ICECandidate was properly sent
		try await assertDidSendMessage(primitive)
	}

	/// Trigger the `create local answer` event.
	private func createAndSendAnswer(_ primitive: IdentifiedPrimitive<RTCPrimitive>, peerConnection: MockPeerConnection) async throws {
		// Await for create local answer to be triggered
		await peerConnection.onCreateLocalAnswer()

		// Complete the create local answer request
                peerConnection.completeCreateLocalAnswerRequest(with: .success(primitive.content.answer!))

		// Await for the created local answer to be configured on the peerConnection
		let configuredAnswer = await peerConnection.configuredLocalAnswer.prefix(1).collect().first!

		// Assert that the configured answer does match the created one
                XCTAssertEqual(configuredAnswer, primitive.content.answer)

		// Assert that the created answer is properly sent through the webSocket
                try await assertDidSendMessage(primitive)
	}

	/// Assert the given primitive was properly sent through the WebSocketClient
	func assertDidSendMessage(_ primitive: IdentifiedPrimitive<RTCPrimitive>) async throws {
                let sentMessage = try await webSocketClient
                        .sentMessagesSequence
                        .map {
                                try await self.jsonDecoder.decode(ClientMessage.self, from: $0)
                                
                        }
                        .filter {
                                $0.targetClientId == primitive.id && $0.primitive == primitive.content
                        }
                        .prefix(1)
                        .collect()
                        .first!
		webSocketClient.respondToRequest(message: .success(sentMessage.requestId))
	}

	/// Creates a client message that is to be received from remote client
	func makeClientMessage(_ primitive: IdentifiedPrimitive<RTCPrimitive>) throws -> JSONValue {
		let requestId = RequestID.any.rawValue
                let encoded = try jsonEncoder.encode(primitive.content.payload)
		let encrypted = try Self.encryptionKey.encrypt(data: encoded)
		let data = JSONValue.dictionary([
			"requestId": .string(requestId),
                        "method": .string(ClientMessage.Method(from: primitive.content).rawValue),
                        "targetClientId": .string(UUID().uuidString),
			"encryptedPayload": .string(encrypted.hex),
		])

		let remoteData = JSONValue.dictionary([
			"info": .string("remoteData"),
			"requestId": .string(requestId),
                        "remoteClientId": .string(primitive.id.rawValue),
			"data": data,
		])

		return remoteData
	}

	/// Creates a PeerConnectionClient for the given remoteClientID and returns also its collaborators
	private func makePeerConnectionClient(_ remoteClientID: ClientID) -> (client: PeerConnectionClient, peerConnection: MockPeerConnection, delegate: MockPeerConnectionDelegate) {
		let peerConnection = MockPeerConnection(dataChannel: .success(dataChannelClient))
		let delegate = MockPeerConnectionDelegate()
		return (
			try! PeerConnectionClient(id: remoteClientID, peerConnection: peerConnection, delegate: delegate),
			peerConnection,
			delegate
		)
	}
}

// MARK: - FailedToCreatePeerConnectionError + Equatable
extension FailedToCreatePeerConnectionError: Equatable {
	public static func == (lhs: RadixConnect.FailedToCreatePeerConnectionError, rhs: RadixConnect.FailedToCreatePeerConnectionError) -> Bool {
		lhs.remoteClientId == rhs.remoteClientId && lhs.underlyingError as NSError == rhs.underlyingError as NSError
	}
}
