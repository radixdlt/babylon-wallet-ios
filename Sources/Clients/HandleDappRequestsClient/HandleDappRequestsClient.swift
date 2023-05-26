import AppPreferencesClient
import AsyncExtensions
import ClientPrelude
import ComposableArchitecture // actually CasePaths... but CI fails if we do `import CasePaths` 🤷‍♂️
import GatewaysClient
import RadixConnectClient
import SharedModels

// MARK: - DappRequestQueueClient
public struct DappRequestQueueClient: DependencyKey, Sendable {
	public let requests: AnyAsyncSequence<P2P.RTCIncomingDappNonValidatedRequest>
	public let addWalletRequest: (P2P.Dapp.Request.Items) -> Void
	public let sendResponse: (P2P.RTCOutgoingMessage) async throws -> Void
}

extension DappRequestQueueClient {
	public static var liveValue: DappRequestQueueClient = {
		let requestsStream: AsyncPassthroughSubject<P2P.RTCIncomingDappNonValidatedRequest> = .init()
		@Dependency(\.radixConnectClient) var radixConnectClient

		Task {
			_ = await radixConnectClient.loadFromProfileAndConnectAll()

			for try await incomingRequest in await radixConnectClient.receiveRequests(/P2P.RTCMessageFromPeer.Request.dapp) {
				guard !Task.isCancelled else {
					return
				}
				requestsStream.send(incomingRequest)
			}
		}
		return .init(
			requests: requestsStream.share().eraseToAnyAsyncSequence(),
			addWalletRequest: { items in
				let request = P2P.RTCIncomingDappNonValidatedRequest(
					result: .success(.init(
						id: .init(UUID().uuidString),
						items: items,
						metadata: .init(
							version: P2P.Dapp.currentVersion,
							networkId: .default,
							origin: DappOrigin.wallet.urlString.rawValue,
							dAppDefinitionAddress: DappDefinitionAddress.wallet.address
						)
					)),
					route: .wallet
				)

				requestsStream.send(request)
			},
			sendResponse: { message in
				switch message {
				case let .response(response, .rtc(route)):
					try await radixConnectClient.sendResponse(response, route)
				default:
					break
				}
			}
		)
	}()
}

extension DependencyValues {
	public var dappRequestQueueClient: DappRequestQueueClient {
		get { self[DappRequestQueueClient.self] }
		set { self[DappRequestQueueClient.self] = newValue }
	}
}
