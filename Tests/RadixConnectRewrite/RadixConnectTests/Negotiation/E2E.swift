@testable import RadixConnect
import TestingPrelude
import CryptoKit

@MainActor
final class E2ETests: TestCase {
        let webSocketBaseURL = URL(string: "wss://signaling-server-dev.rdx-works-main.extratools.works")!
        
//        func test() async throws {
//                let random32Bytes: Data = SymmetricKey(size: .bits256).withUnsafeBytes({ Data($0) })
//                let connectionId: SignalingServerConnectionID = try .init(.init(.init(data: random32Bytes)))
//
//
//                let rtcClients = RTCClients(signalingServerBaseURL: .devSignalingServer)
//                try await rtcClients.add(connectionId)
//
//                // Negotiate 3 connection in parallel
//
//                let (webPagePeerConnectionsStream, webPagePeerConnectionsContinuation) = AsyncStream<PeerConnectionClient>.streamWithContinuation()
//                Task {
//                        let webPagePeerConnection = try await OfferingPeerConnectionBuilder.negotiatePeerConnection(
//                                signalingServerClient: try! SignalingClient(connectionId: connectionId, source: .extension, baseURL: webSocketBaseURL)
//                        )
//                        webPagePeerConnectionsContinuation.yield(webPagePeerConnection)
//                }
//
//                Task {
//                        let webPagePeerConnection = try await OfferingPeerConnectionBuilder.negotiatePeerConnection(
//                                signalingServerClient: try! SignalingClient(connectionId: connectionId, source: .extension, baseURL: webSocketBaseURL)
//                        )
//                        webPagePeerConnectionsContinuation.yield(webPagePeerConnection)
//                }
//
//                Task {
//                        let webPagePeerConnection = try await OfferingPeerConnectionBuilder.negotiatePeerConnection(
//                                signalingServerClient: try! SignalingClient(connectionId: connectionId, source: .extension, baseURL: webSocketBaseURL)
//                        )
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
//                let testData = try Data.random(length: DataChannelAssembledMessage.chunkSize * 4)
//                try await webPage.sendData(testData)
//
//                let receivedMessage = try await rtcClients.incommingMessages.prefix(1).collect().first!
//                XCTAssertEqual(try! receivedMessage.content.content.get().messageContent, testData)
//
//                let responseData = try Data.random(length: DataChannelAssembledMessage.chunkSize * 4)
//                Task {
//                        try await rtcClients.sendMessage(
//                                .init(
//                                        connectionId: receivedMessage.connectionId,
//                                        content: .init(peerConnectionId: receivedMessage.content.peerConnectionId, content: responseData)
//                                )
//                        )
//                }
//
//                let receivedMessageWeb = try await webPage.receivedMessagesStream().prefix(1).collect().first!.get()
//                XCTAssertEqual(receivedMessageWeb.messageContent, responseData)
//        }
}
