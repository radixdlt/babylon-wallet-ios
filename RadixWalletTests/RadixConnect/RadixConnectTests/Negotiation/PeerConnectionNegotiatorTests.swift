// @testable import Radix_Wallet_Dev
// import XCTest
//
//// MARK: - PeerConnectionNegotiatorTests
// @MainActor
// final class PeerConnectionNegotiatorTests: TestCase {
//	// Static config
//	static let encryptionKey = try! SignalingClient.EncryptionKey(rawValue: .init(data: .deadbeef32Bytes))
//	lazy var jsonDecoder: JSONDecoder = {
//		let decoder = JSONDecoder()
//		decoder.userInfo[.clientMessageEncryptionKey] = Self.encryptionKey
//		return decoder
//	}()
//
//	lazy var jsonEncoder: JSONEncoder = {
//		let encoder = JSONEncoder()
//		encoder.userInfo[.clientMessageEncryptionKey] = Self.encryptionKey
//		return encoder
//	}()
//
//	// Shared clients
//	let dataChannelDelegate = DataChannelDelegateMock()
//	lazy var dataChannelClient = DataChannelClient(dataChannel: DataChannelMock(), delegate: dataChannelDelegate)
//	let webSocketClient = MockWebSocketClient()
//	lazy var signalingClient = SignalingClient(encryptionKey: Self.encryptionKey,
//	                                           transport: webSocketClient)
//
//	func test_makePeerConnection_happyFlow() async throws {
//		let remoteClientID = RemoteClientID.any
//		let (client, peerConnection, delegate) = makePeerConnectionClient(remoteClientID)
//		let peerConnectionFactory = MockPeerConnectionFactory(clients: [client])
//		let conenctionBuilder = PeerConnectionNegotiator(signalingClient: signalingClient, factory: peerConnectionFactory)
//
//		// Negotiate the PeerConnection
//		try await performNegotiation(forClient: remoteClientID, peerConnection: peerConnection, peerConnectionDelegate: delegate)
//
//		// Await for PeerConnection to be estblished
//		let result = try await conenctionBuilder.negotiationResults.first()
//		XCTAssertEqual(result.map(\.id), .success(.init(remoteClientID.rawValue)))
//	}
//
//	// TODO: For some reason fails on CI with timeout, to investigate
////	func test_makePeerConnection_parallelNegotiation() async throws {
////		// Configure 4 peer connections to be negotiated in parallel
////		let remoteClientId2 = RemoteClientID(rawValue: UUID().uuidString)
////		let remoteClientId3 = RemoteClientID(rawValue: UUID().uuidString)
////		let remoteClientId1 = RemoteClientID(rawValue: UUID().uuidString)
////		let remoteClientId4 = RemoteClientID(rawValue: UUID().uuidString)
////
////		let (client1, peerConnection1, delegate1) = makePeerConnectionClient(remoteClientId1)
////		let (client2, peerConnection2, delegate2) = makePeerConnectionClient(remoteClientId2)
////		let (client3, peerConnection3, delegate3) = makePeerConnectionClient(remoteClientId3)
////		let (client4, peerConnection4, delegate4) = makePeerConnectionClient(remoteClientId4)
////		let peerConnectionFactory = MockPeerConnectionFactory(clients: [client1, client2, client3, client4])
////		let conenctionBuilder = PeerConnectionNegotiator(signalingClient: signalingClient, factory: peerConnectionFactory)
////
////		let negotiationResults = try await doAsync(withTimeout: .seconds(2)) {
////			try await withThrowingTaskGroup(of: Void.self, body: { group in
////				group.addTask {
////					try await self.performNegotiation(forClient: remoteClientId1, peerConnection: peerConnection1, peerConnectionDelegate: delegate1)
////				}
////
////				group.addTask {
////					try await self.performNegotiation(forClient: remoteClientId2, peerConnection: peerConnection2, peerConnectionDelegate: delegate2)
////				}
////
////				group.addTask {
////					try await self.performNegotiation(forClient: remoteClientId3, peerConnection: peerConnection3, peerConnectionDelegate: delegate3)
////				}
////
////				group.addTask {
////					try await self.performFailingNegotiation(forClient: remoteClientId4, peerConnection: peerConnection4, peerConnectionDelegate: delegate4)
////				}
////
////				try await group.waitForAll()
////			})
////
////			return try await conenctionBuilder.negotiationResults.prefix(4).collect()
////		}
////
////		/// We are interested only comparing the created `PeerConnectionClient.id`'s, or the failure
////		let result: [
////			PeerConnectionClient.ID:
////				Result<PeerConnectionClient.ID, PeerConnectionNegotiator.FailedToCreatePeerConnectionError>
////		] = negotiationResults
////			.reduce(into: [:]) { partialResult, nextResult in
////				switch nextResult {
////				case let .success(peerConnection):
////					partialResult[peerConnection.id] = .success(peerConnection.id)
////				case let .failure(failure):
////					partialResult[.init(failure.remoteClientId.rawValue)] = .failure(failure)
////				}
////			}
////
////		let expectedResults: [PeerConnectionClient.ID: Result<PeerConnectionClient.ID, PeerConnectionNegotiator.FailedToCreatePeerConnectionError>] = [
////			.init(remoteClientId1.rawValue): .success(.init(remoteClientId1.rawValue)),
////			.init(remoteClientId2.rawValue): .success(.init(remoteClientId2.rawValue)),
////			.init(remoteClientId3.rawValue): .success(.init(remoteClientId3.rawValue)),
////			.init(remoteClientId4.rawValue): .failure(PeerConnectionNegotiator.FailedToCreatePeerConnectionError(remoteClientId: remoteClientId4, underlyingError: NSError(domain: "dom", code: 1))),
////		]
////
////		XCTAssertEqual(result, expectedResults)
////	}
//
//	func test_makePeerConnection_failedToSetRemoteDescriptionAfterOffer() async throws {
//		let remoteClientId = RemoteClientID.any
//		let (client, peerConnection, delegate) = makePeerConnectionClient(remoteClientId)
//		let peerConnectionFactory = MockPeerConnectionFactory(clients: [client])
//		let conenctionBuilder = PeerConnectionNegotiator(signalingClient: signalingClient, factory: peerConnectionFactory)
//
//		let peerConnectionTask = Task {
//			try await conenctionBuilder.negotiationResults.first()
//		}
//
//		try webSocketClient.receiveIncomingMessage(
//			makeClientMessage(.anyOffer(for: remoteClientId))
//		)
//		delegate.sendNegotiationNeededEvent()
//
//		// Await set offer
//		_ = try await peerConnection.onOfferConfigured()
//		peerConnection.completeSetRemoteDescription(with: .failure(NSError(domain: "dom", code: 1)))
//
//		let result = try await peerConnectionTask.value
//
//		XCTAssertThrowsError(try result.get())
//	}
//
//	func test_makePeerConnection_failsToGenerateAnswer() async throws {
//		let remoteClientId = RemoteClientID.any
//		let (client, peerConnection, delegate) = makePeerConnectionClient(remoteClientId)
//		let peerConnectionFactory = MockPeerConnectionFactory(clients: [client])
//		let conenctionBuilder = PeerConnectionNegotiator(signalingClient: signalingClient, factory: peerConnectionFactory)
//
//		let peerConnectionTask = Task {
//			try await conenctionBuilder.negotiationResults.first()
//		}
//
//		try await receiveRemoteOffer(.anyOffer(for: remoteClientId), peerConnection: peerConnection, peerConnectionDelegate: delegate)
//
//		await peerConnection.onLocalAnswerCreated()
//		peerConnection.completeCreateLocalAnswerRequest(with: .failure(NSError(domain: "dom", code: 1)))
//
//		let result = try await peerConnectionTask.value
//
//		XCTAssertThrowsError(try result.get())
//	}
//
//	func test_makePeerConnection_failsToSendAnswerToRemote() async throws {
//		let remoteClientId = RemoteClientID.any
//		let (client, peerConnection, delegate) = makePeerConnectionClient(remoteClientId)
//		let peerConnectionFactory = MockPeerConnectionFactory(clients: [client])
//		let conenctionBuilder = PeerConnectionNegotiator(signalingClient: signalingClient, factory: peerConnectionFactory)
//
//		let peerConnectionTask = Task {
//			try await conenctionBuilder.negotiationResults.first()
//		}
//
//		try await receiveRemoteOffer(.anyOffer(for: remoteClientId), peerConnection: peerConnection, peerConnectionDelegate: delegate)
//
//		await peerConnection.onLocalAnswerCreated()
//		peerConnection.completeCreateLocalAnswerRequest(with: .success(.any))
//
//		_ = try await peerConnection.onAnswerConfigured()
//		peerConnection.completeSetLocalDescription(with: .success(()))
//
//		let message = try await jsonDecoder.decode(SignalingClient.ClientMessage.self, from: webSocketClient.onClientMessageSent())
//		webSocketClient.respondToRequest(message: .failure(.noRemoteClientToTalkTo(.init(message.requestId.rawValue))))
//		let result = try await peerConnectionTask.value
//
//		XCTAssertThrowsError(try result.get())
//	}
//
//	// MARK: - Private
//
//	/// Performs the full successfull negotiation flow for the given remoteClientId
//	private func performNegotiation(
//		forClient remoteClientId: RemoteClientID,
//		peerConnection: MockPeerConnection,
//		peerConnectionDelegate: MockPeerConnectionDelegate
//	) async throws {
//		// Receive Incoming offer from remoteClientId
//		try await receiveRemoteOffer(.anyOffer(for: remoteClientId), peerConnection: peerConnection, peerConnectionDelegate: peerConnectionDelegate)
//
//		// Send answer
//		try await createAndSendAnswer(.anyAnswer(for: remoteClientId), peerConnection: peerConnection)
//
//		// Receive ICECandidate
//		try await receiveICECandidate(.anyICECandidate(for: remoteClientId), peerConnection: peerConnection)
//
//		// Send ICECandidate
//		try await sendICECandidate(.anyICECandidate(for: remoteClientId), peerConnectionDelegate: peerConnectionDelegate)
//
//		// When ICEConnection state is connected the negotiation is completed
//		peerConnectionDelegate.sendICEConnectionStateEvent(.connected)
//		dataChannelDelegate.sendDataChannelReadyState(.connected)
//	}
//
//	/// Performs a failing negotiation flow for the given remoteClientId
//	private func performFailingNegotiation(
//		forClient remoteClientId: RemoteClientID,
//		peerConnection: MockPeerConnection,
//		peerConnectionDelegate: MockPeerConnectionDelegate
//	) async throws {
//		try webSocketClient.receiveIncomingMessage(
//			makeClientMessage(.anyOffer(for: remoteClientId))
//		)
//
//		peerConnectionDelegate.sendNegotiationNeededEvent()
//
//		// Await set offer
//		_ = try await peerConnection.onOfferConfigured()
//		peerConnection.completeSetRemoteDescription(with: .failure(NSError(domain: "dom", code: 1)))
//	}
//
//	/// This function will trigger the negotiation flow for the given offer,
//	/// as well it will assert that the Offer was properly set on the created PeerConnection.
//	private func receiveRemoteOffer(
//		_ primitive: IdentifiedRTCPrimitive,
//		peerConnection: MockPeerConnection,
//		peerConnectionDelegate: MockPeerConnectionDelegate
//	) async throws {
//		// Receive the Incoming offer
//		try webSocketClient.receiveIncomingMessage(
//			makeClientMessage(primitive)
//		)
//
//		// Before setting the Offer, the negotiation needed event has to occur
//		peerConnectionDelegate.sendNegotiationNeededEvent()
//
//		// Await for the remote offer to be configured on the peer connection
//		let configuredOffer = try await peerConnection.onOfferConfigured()
//
//		// Assert that the configured offer does amtch the Incoming offer
//		XCTAssertEqual(configuredOffer, primitive.value.offer!)
//
//		// Complete the set remote offer action on peerConnection, thus allowing the negotiation to flow further
//		peerConnection.completeSetRemoteDescription(with: .success(()))
//	}
//
//	/// Trigger a `receiveICECandidate` event, as well assert that the received ICECanddiate is properly set on the PeerConnection
//	private func receiveICECandidate(
//		_ primitive: IdentifiedRTCPrimitive,
//		peerConnection: MockPeerConnection
//	) async throws {
//		// Receive the Incoming ICECandidate
//		try webSocketClient.receiveIncomingMessage(
//			makeClientMessage(primitive)
//		)
//
//		// Await for the ICECandidate to be configured on peerConnection
//		let configuredICECandidate = try await peerConnection.configuredICECandidate.first()
//
//		// Assert that the configured ICECandidate does match the Incoming ICECanddiate
//		XCTAssertEqual(configuredICECandidate, primitive.value.iceCandidate)
//
//		// Complete the add ICECandidate action on PeerConnection
//		peerConnection.completeAddICECandidate(with: .success(()))
//	}
//
//	/// Trigger the `generated local ICECandidate` event, as well assert that the generated ICECandidate is sent throught he WebSocket to the proper client
//	private func sendICECandidate(
//		_ primitive: IdentifiedRTCPrimitive,
//		peerConnectionDelegate: MockPeerConnectionDelegate
//	) async throws {
//		// Generate local ICECandidate
//		peerConnectionDelegate.generateICECandiddate(primitive.value.iceCandidate!)
//
//		// Assert that the generated ICECandidate was properly sent
//		try await assertDidSendMessage(primitive)
//	}
//
//	/// Trigger the `create local answer` event.
//	private func createAndSendAnswer(
//		_ primitive: IdentifiedRTCPrimitive,
//		peerConnection: MockPeerConnection
//	) async throws {
//		// Await for create local answer to be triggered
//		await peerConnection.onLocalAnswerCreated()
//
//		// Complete the create local answer request
//		peerConnection.completeCreateLocalAnswerRequest(with: .success(primitive.value.answer!))
//
//		let answer = try await peerConnection.onAnswerConfigured()
//		peerConnection.completeSetLocalDescription(with: .success(()))
//
//		// Assert that the configured answer does match the created one
//		XCTAssertEqual(answer, primitive.value.answer!)
//
//		// Assert that the created answer is properly sent through the webSocket
//		try await assertDidSendMessage(primitive)
//	}
//
//	/// Assert the given primitive was properly sent through the WebSocketClient
//	func assertDidSendMessage(_ primitive: IdentifiedRTCPrimitive) async throws {
//		let sentMessage = try await webSocketClient
//			.sentMessagesSequence
//			.map {
//				try await self.jsonDecoder.decode(SignalingClient.ClientMessage.self, from: $0)
//			}
//			.filter {
//				$0.targetClientId == primitive.id && $0.primitive == primitive.value
//			}
//			.first()
//		webSocketClient.respondToRequest(message: .success(sentMessage.requestId))
//	}
//
//	/// Creates a client message that is to be received from remote client
//	func makeClientMessage(_ primitive: IdentifiedRTCPrimitive) throws -> JSONValue {
//		let requestId = SignalingClient.ClientMessage.RequestID.any.rawValue
//		let encoded = try jsonEncoder.encode(primitive.value.payload)
//		let encrypted = try EncryptionScheme.version1.encrypt(data: encoded, encryptionKey: Self.encryptionKey.symmetric)
//		let data = JSONValue.dictionary([
//			"requestId": .string(requestId),
//			"method": .string(SignalingClient.ClientMessage.Method(from: primitive.value).rawValue),
//			"targetClientId": .string(UUID().uuidString),
//			"encryptedPayload": .string(encrypted.hex),
//		])
//
//		let remoteData = JSONValue.dictionary([
//			"info": .string("remoteData"),
//			"requestId": .string(requestId),
//			"remoteClientId": .string(primitive.id.rawValue),
//			"data": data,
//		])
//
//		return remoteData
//	}
//
//	/// Creates a PeerConnectionClient for the given remoteClientID and returns also its collaborators
//	private func makePeerConnectionClient(_ remoteClientID: RemoteClientID) -> (client: PeerConnectionClient, peerConnection: MockPeerConnection, delegate: MockPeerConnectionDelegate) {
//		let peerConnection = MockPeerConnection(dataChannel: .success(dataChannelClient))
//		let delegate = MockPeerConnectionDelegate()
//		return (
//			try! PeerConnectionClient(id: .init(remoteClientID.rawValue), peerConnection: peerConnection, delegate: delegate),
//			peerConnection,
//			delegate
//		)
//	}
// }
//
//// MARK: - PeerConnectionNegotiator.FailedToCreatePeerConnectionError + Equatable
// extension PeerConnectionNegotiator.FailedToCreatePeerConnectionError: Equatable {
//	public static func == (lhs: Self, rhs: Self) -> Bool {
//		lhs.remoteClientId == rhs.remoteClientId && lhs.underlyingError as NSError == rhs.underlyingError as NSError
//	}
// }
