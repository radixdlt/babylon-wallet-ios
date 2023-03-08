// TODO: Revive this test and see if it can run in GH actions
// import CryptoKit
// @testable import RadixConnect
// import TestingPrelude
// import SharedModels
//
// @MainActor
// final class E2ETests: TestCase {
//	let webSocketBaseURL = URL(string: "wss://signaling-server-dev.rdx-works-main.extratools.works")!
//
//        func test() async throws {
//                let random32Bytes: Data = SymmetricKey(size: .bits256).withUnsafeBytes({ Data($0) })
//                let connectionPassword = try ConnectionPassword(.init(data: random32Bytes))
//
//                let walletRTCClients = RTCClients(peerConnectionFactory: WebRTCFactory(), signalingServerBaseURL: webSocketBaseURL)
//                try await walletRTCClients.connect(connectionPassword)
//
//                let webPage1RTCClients = RTCClients(peerConnectionFactory: WebRTCFactory(), signalingServerBaseURL: webSocketBaseURL)
//                try await walletRTCClients.connect(connectionPassword)
//
//                // Negotiate 3 connection in parallel
//
//                let (webPagePeerConnectionsStream, webPagePeerConnectionsContinuation) = AsyncStream<PeerConnectionClient>.streamWithContinuation()
//                Task {
//                        let ss = try! SignalingClient(password: connectionPassword, source: .extension, baseURL: webSocketBaseURL)
//                        let webPagePeerConnection = try await PeerConnectionNegotiator(signalingClient: ss, factory: WebRTCFactory(), isOfferer: true).negotiationResults.first().get()
//                        webPagePeerConnectionsContinuation.yield(webPagePeerConnection)
//                }
//
//                Task {
//                        let ss = try! SignalingClient(password: connectionPassword, source: .extension, baseURL: webSocketBaseURL)
//                        let webPagePeerConnection = try await PeerConnectionNegotiator(signalingClient: ss, factory: WebRTCFactory(), isOfferer: true).negotiationResults.first().get()
//                        webPagePeerConnectionsContinuation.yield(webPagePeerConnection)
//                }
//
//                Task {
//                        let ss = try! SignalingClient(password: connectionPassword, source: .extension, baseURL: webSocketBaseURL)
//                        let webPagePeerConnection = try await PeerConnectionNegotiator(signalingClient: ss, factory: WebRTCFactory(), isOfferer: true).negotiationResults.first().get()
//                        webPagePeerConnectionsContinuation.yield(webPagePeerConnection)
//                }
//
//                // Wait for all 3 connections to be established
//                let webPagePeerConnections = await webPagePeerConnectionsStream.prefix(3).collect()
//
//                // Assert communication
//
//                try await assertCommunicationWorks(with: webPagePeerConnections[0], rtcClients)
//                try await assertCommunicationWorks(with: webPagePeerConnections[1], rtcClients)
//                try await assertCommunicationWorks(with: webPagePeerConnections[2], rtcClients)
//        }
//
//        private func assertCommunicationWorks(with webPage: PeerConnectionClient, _ rtcClients: RTCClients) async throws {
//                let request = P2P.FromDapp.WalletInteraction.testValue
//                try await webPage.sendData(JSONEncoder().encode(request))
//
//                let receivedMessage = try await rtcClients.IncomingMessages.first()
//                XCTAssertEqual(try! receivedMessage.peerMessage.content.get()., testData)
//
//                let responseData = try Data.random(length: DataChannelClient.AssembledMessage.chunkSize * 4)
//                Task {
//                        try await rtcClients.sendMessage(
//                                .init(
//                                        connectionId: receivedMessage.connectionId,
//                                        content: .init(peerConnectionId: receivedMessage.content.peerConnectionId, content: responseData)
//                                )
//                        )
//                }
//
//                let receivedMessageWeb = try await webPage.receivedMessagesStream().first().get()
//                XCTAssertEqual(receivedMessageWeb.messageContent, responseData)
//        }
// }
//
// extension P2P.FromDapp.WalletInteraction {
//        static var testValue: Self {
//                .init(id: .previewValue, items: .request(.unauthorized(.init(oneTimeAccounts: .previewValue))), metadata: .previewValue)
//        }
// }
