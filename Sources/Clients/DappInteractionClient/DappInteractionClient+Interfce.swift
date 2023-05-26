import AsyncExtensions
import ClientPrelude
import SharedModels

// MARK: - DappInteractionClient
public struct DappInteractionClient: Sendable {
	public let requests: AnyAsyncSequence<ValidatedDappRequest>
	public let addWalletRequest: AddWalletRequest
	public let sendResponse: SendResponse

	public init(
		requests: AnyAsyncSequence<ValidatedDappRequest>,
		addWalletRequest: @escaping AddWalletRequest,
		sendResponse: @escaping SendResponse
	) {
		self.requests = requests
		self.addWalletRequest = addWalletRequest
		self.sendResponse = sendResponse
	}
}

extension DappInteractionClient {
	public typealias AddWalletRequest = @Sendable (P2P.Dapp.Request.Items) -> Void
	public typealias SendResponse = @Sendable (P2P.RTCOutgoingMessage) async throws -> Void
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
			case badContent(BadContent)
			case p2pError(String)
			public enum BadContent: Sendable, Hashable {
				case numberOfAccountsInvalid
			}
		}
	}
}
