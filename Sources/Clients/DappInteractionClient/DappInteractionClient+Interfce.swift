import AsyncExtensions
import ClientPrelude
import EngineKit
import SharedModels

// MARK: - DappInteractionClient
public struct DappInteractionClient: Sendable {
	public let interactions: AnyAsyncSequence<ValidatedDappRequest>
	public let addWalletInteraction: AddWalletInteraction
	public let completeInteraction: CompleteInteraction

	public init(
		interactions: AnyAsyncSequence<ValidatedDappRequest>,
		addWalletInteraction: @escaping AddWalletInteraction,
		completeInteraction: @escaping CompleteInteraction
	) {
		self.interactions = interactions
		self.addWalletInteraction = addWalletInteraction
		self.completeInteraction = completeInteraction
	}
}

extension DappInteractionClient {
	public typealias AddWalletInteraction = @Sendable (P2P.Dapp.Request.Items) async -> Void
	public typealias CompleteInteraction = @Sendable (P2P.RTCOutgoingMessage) async throws -> Void
}

extension DappInteractionClient {
	public struct RequestEnvelope: Sendable, Hashable {
		public let route: P2P.Route
		public let request: P2P.Dapp.Request

		public init(route: P2P.Route, request: P2P.Dapp.Request) {
			self.route = route
			self.request = request
		}
	}

	public enum ValidatedDappRequest: Sendable, Hashable {
		case valid(RequestEnvelope)
		case invalid(Invalid)

		public enum Invalid: Sendable, Hashable {
			case incompatibleVersion(connectorExtensionSent: P2P.Dapp.Version, walletUses: P2P.Dapp.Version)
			case wrongNetworkID(connectorExtensionSent: NetworkID, walletUses: NetworkID)
			case invalidDappDefinitionAddress(gotStringWhichIsAnInvalidAccountAddress: String)
			case invalidOrigin(invalidURLString: String)
			case dAppValidationError
			case badContent(BadContent)
			case p2pError(String)
			public enum BadContent: Sendable, Hashable {
				case numberOfAccountsInvalid
			}
		}
	}
}
