// MARK: - DappInteractionClient
public struct DappInteractionClient: Sendable {
	public let interactions: AnyAsyncSequence<Result<ValidatedDappRequest, Error>>
	public let addWalletInteraction: AddWalletInteraction
	public let completeInteraction: CompleteInteraction

	public init(
		interactions: AnyAsyncSequence<Result<ValidatedDappRequest, Error>>,
		addWalletInteraction: @escaping AddWalletInteraction,
		completeInteraction: @escaping CompleteInteraction
	) {
		self.interactions = interactions
		self.addWalletInteraction = addWalletInteraction
		self.completeInteraction = completeInteraction
	}
}

extension DappInteractionClient {
	public enum WalletInteraction: String, Sendable, Hashable {
		case accountDepositSettings
		case accountTransfer
		case dappVerification
	}

	public typealias AddWalletInteraction = @Sendable (_ items: P2P.Dapp.Request.Items, _ interaction: WalletInteraction) async -> P2P.RTCOutgoingMessage.Response?
	public typealias CompleteInteraction = @Sendable (P2P.RTCOutgoingMessage) async throws -> Void
}

extension P2P.Dapp.Request.ID {
	public static func walletInteractionID(for interaction: DappInteractionClient.WalletInteraction) -> Self {
		"\(interaction.rawValue)_\(UUID().uuidString)"
	}

	public var isWalletAccountDepositSettingsInteraction: Bool {
		rawValue.hasPrefix(DappInteractionClient.WalletInteraction.accountDepositSettings.rawValue)
	}

	public var isWalletAccountTransferInteraction: Bool {
		rawValue.hasPrefix(DappInteractionClient.WalletInteraction.accountTransfer.rawValue)
	}

	public var isWalletInteraction: Bool {
		isWalletAccountTransferInteraction || isWalletAccountDepositSettingsInteraction
	}

	public var isDappVerification: Bool {
		rawValue.hasPrefix(DappInteractionClient.WalletInteraction.dappVerification.rawValue)
	}
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

	public struct ValidatedDappRequest: Sendable, Hashable {
		public let route: P2P.Route
		public let request: Request

		public init(route: P2P.Route, request: Request) {
			self.route = route
			self.request = request
		}

		public enum Request: Sendable, Hashable {
			case valid(P2P.Dapp.Request)
			case invalid(request: P2P.Dapp.RequestUnvalidated, reason: InvalidRequestReason)
		}

		public enum InvalidRequestReason: Sendable, Hashable {
			case incompatibleVersion(connectorExtensionSent: P2P.Dapp.Version, walletUses: P2P.Dapp.Version)
			case wrongNetworkID(connectorExtensionSent: NetworkID, walletUses: NetworkID)
			case invalidDappDefinitionAddress(gotStringWhichIsAnInvalidAccountAddress: String)
			case invalidOrigin(invalidURLString: String)
			case dAppValidationError(String)
			case badContent(BadContent)
			public enum BadContent: Sendable, Hashable {
				case numberOfAccountsInvalid
			}
		}
	}
}
