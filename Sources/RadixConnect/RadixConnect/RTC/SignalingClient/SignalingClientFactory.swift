import Foundation
import RadixConnectModels
import CryptoKit

public extension URL {
        static let prodSignalingServer = Self(string: "wss://signaling-server-betanet.radixdlt.com")!
        static let devSignalingServer = Self(string: "wss://signaling-server-dev.rdx-works-main.extratools.works")!
}

extension SignalingClient {
        init(password: ConnectionPassword, source: ClientSource, baseURL: URL) throws {
                let connectionId = try SignalingServerConnectionID(.init(.init(data: Data(SHA256.hash(data: password.data.data)))))
                let connectionURL = try signalingServerURL(connectionID: connectionId, source: source, baseURL: baseURL)
                let webSocket = AsyncWebSocket(url: connectionURL)
                let encryptionKey = try EncryptionKey(.init(data: password.data.data))

                self.init(encryptionKey: encryptionKey, webSocketClient: webSocket, connectionID: connectionId, clientSource: source)
        }
}

// MARK: - FailedToCreateSignalingServerURL
struct FailedToCreateSignalingServerURL: LocalizedError {
        var errorDescription: String? {
                "Failed to create url"
        }
}

// MARK: - QueryParameterName
enum QueryParameterName: String {
        case target, source
}

func signalingServerURL(
        connectionID: SignalingServerConnectionID,
        source: ClientSource = .wallet,
        baseURL: URL = .prodSignalingServer
) throws -> URL {
        let target: ClientSource = source == .wallet ? .extension : .wallet

        let url = baseURL.appendingPathComponent(
                connectionID.hex
        )

        guard
                var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else {
                throw FailedToCreateSignalingServerURL()
        }

        urlComponents.queryItems = [
                .init(
                        name: QueryParameterName.target.rawValue,
                        value: target.rawValue
                ),
                .init(
                        name: QueryParameterName.source.rawValue,
                        value: source.rawValue
                ),
        ]

        guard let serverURL = urlComponents.url else {
                throw FailedToCreateSignalingServerURL()
        }

        return serverURL
}

extension SignalingServerConnectionID {
        var hex: String {
                self.rawValue.data.hex()
        }
}

