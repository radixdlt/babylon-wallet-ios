import AppPreferencesClient
import AsyncExtensions
import ClientPrelude
import ComposableArchitecture // actually CasePaths... but CI fails if we do `import CasePaths` 🤷‍♂️
import GatewaysClient
import RadixConnectClient
import SharedModels

// MARK: - DappInteractionClient
public struct DappInteractionClient: DependencyKey, Sendable {
	public let requests: AnyAsyncSequence<ValidatedDappRequest>
	public let addWalletRequest: (P2P.Dapp.Request.Items) -> Void
	public let sendResponse: (P2P.RTCOutgoingMessage) async throws -> Void
}

extension DappInteractionClient {
	public static var liveValue: DappInteractionClient = {
		let requestsStream: AsyncPassthroughSubject<ValidatedDappRequest> = .init()
		@Dependency(\.radixConnectClient) var radixConnectClient

		Task {
			_ = await radixConnectClient.loadFromProfileAndConnectAll()

			for try await incomingRequest in await radixConnectClient.receiveRequests(/P2P.RTCMessageFromPeer.Request.dapp) {
				guard !Task.isCancelled else {
					return
				}
				await requestsStream.send(validate(incomingRequest))
			}
		}
		return .init(
			requests: requestsStream.share().eraseToAnyAsyncSequence(),
			addWalletRequest: { items in
				let request = ValidatedDappRequest.valid(.init(
					route: .wallet,
					request: .init(
						id: .init(UUID().uuidString),
						items: items,
						metadata: .init(
							version: P2P.Dapp.currentVersion,
							networkId: .default,
							origin: DappOrigin.wallet,
							dAppDefinitionAddress: DappDefinitionAddress.wallet
						)
					)
				))
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

extension DappInteractionClient {
	public struct RequestEnvelope: Sendable, Hashable {
		public let route: P2P.Route
		public let request: P2P.Dapp.Request
	}

	public enum ValidatedDappRequest: Sendable, Hashable {
		case valid(RequestEnvelope)
		case invalid(Invalid)
		public enum Invalid: Sendable, Hashable {
			case incompatibleVersion(connectorExtensionSent: P2P.Dapp.Version, walletUses: P2P.Dapp.Version)
			case wrongNetworkID(connectorExtensionSent: NetworkID, walletUses: NetworkID)
			case invalidDappDefinitionAddress(gotStringWhichIsAnInvalidAccountAddress: String)
			case invalidOrigin(invalidURLString: String)
			case badContent(BadContent)
			case p2pError(String)
			public enum BadContent: Sendable, Hashable {
				case numberOfAccountsInvalid
			}
		}
	}

	/// Validates a received request from Dapp.
	static func validate(
		_ message: P2P.RTCIncomingMessageContainer<P2P.Dapp.RequestUnvalidated>
	) async -> ValidatedDappRequest {
		@Dependency(\.appPreferencesClient) var appPreferencesClient
		@Dependency(\.gatewaysClient) var gatewaysClient

		return await {
			let nonValidated: P2P.Dapp.RequestUnvalidated
			do {
				nonValidated = try message.result.get()
			} catch {
				return .invalid(.p2pError(error.legibleLocalizedDescription))
			}

			let nonvalidatedMeta = nonValidated.metadata
			guard P2P.Dapp.currentVersion == nonvalidatedMeta.version else {
				return .invalid(.incompatibleVersion(connectorExtensionSent: nonvalidatedMeta.version, walletUses: P2P.Dapp.currentVersion))
			}
			let currentNetworkID = await gatewaysClient.getCurrentNetworkID()
			guard currentNetworkID == nonValidated.metadata.networkId else {
				return .invalid(.wrongNetworkID(connectorExtensionSent: nonvalidatedMeta.networkId, walletUses: currentNetworkID))
			}

			let dappDefinitionAddress: DappDefinitionAddress
			do {
				dappDefinitionAddress = try DappDefinitionAddress(
					address: nonValidated.metadata.dAppDefinitionAddress
				)
			} catch {
				return .invalid(.invalidDappDefinitionAddress(gotStringWhichIsAnInvalidAccountAddress: nonvalidatedMeta.dAppDefinitionAddress))
			}

			if case let .request(readRequest) = nonValidated.items {
				switch readRequest {
				case let .authorized(authorized):
					if authorized.oneTimeAccounts?.numberOfAccounts.isValid == false {
						return .invalid(.badContent(.numberOfAccountsInvalid))
					}
					if authorized.ongoingAccounts?.numberOfAccounts.isValid == false {
						return .invalid(.badContent(.numberOfAccountsInvalid))
					}
				case let .unauthorized(unauthorized):
					if unauthorized.oneTimeAccounts?.numberOfAccounts.isValid == false {
						return .invalid(.badContent(.numberOfAccountsInvalid))
					}
				}
			}

			guard
				let originURL = URL(string: nonvalidatedMeta.origin),
				let nonEmptyOriginURLString = NonEmptyString(rawValue: nonvalidatedMeta.origin)
			else {
				return .invalid(.invalidOrigin(invalidURLString: nonvalidatedMeta.origin))
			}
			let origin = DappOrigin(urlString: nonEmptyOriginURLString, url: originURL)

			let metadataValidDappDefAddres = P2P.Dapp.Request.Metadata(
				version: nonvalidatedMeta.version,
				networkId: nonvalidatedMeta.networkId,
				origin: origin,
				dAppDefinitionAddress: dappDefinitionAddress
			)

			return .valid(.init(
				route: message.route,
				request: .init(
					id: nonValidated.id,
					items: nonValidated.items,
					metadata: metadataValidDappDefAddres
				)
			))
		}()
	}
}

extension DependencyValues {
	public var dappInteractionClient: DappInteractionClient {
		get { self[DappInteractionClient.self] }
		set { self[DappInteractionClient.self] = newValue }
	}
}
