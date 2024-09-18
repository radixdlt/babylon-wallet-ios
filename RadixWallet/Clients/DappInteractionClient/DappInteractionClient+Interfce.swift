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
		case accountLockerClaim
	}

	public typealias AddWalletInteraction = @Sendable (_ items: DappToWalletInteractionItems, _ interaction: WalletInteraction) async -> P2P.RTCOutgoingMessage.Response?
	public typealias CompleteInteraction = @Sendable (P2P.RTCOutgoingMessage) async throws -> Void
}

extension WalletInteractionId {
	public static func walletInteractionID(for interaction: DappInteractionClient.WalletInteraction) -> Self {
		"\(interaction.rawValue)_\(UUID().uuidString)"
	}

	public var isWalletAccountDepositSettingsInteraction: Bool {
		hasPrefix(DappInteractionClient.WalletInteraction.accountDepositSettings.rawValue)
	}

	public var isWalletAccountTransferInteraction: Bool {
		hasPrefix(DappInteractionClient.WalletInteraction.accountTransfer.rawValue)
	}

	public var isWalletAccountLockerClaimInteraction: Bool {
		hasPrefix(DappInteractionClient.WalletInteraction.accountLockerClaim.rawValue)
	}

	public var isWalletInteraction: Bool {
		isWalletAccountTransferInteraction || isWalletAccountDepositSettingsInteraction || isWalletAccountLockerClaimInteraction
	}
}

extension DappInteractionClient {
	public struct RequestEnvelope: Sendable, Hashable {
		public let route: P2P.Route
		public let interaction: DappToWalletInteraction
		public let requiresOriginValidation: Bool

		public init(route: P2P.Route, interaction: DappToWalletInteraction, requiresOriginValidation: Bool) {
			self.route = route
			self.interaction = interaction
			self.requiresOriginValidation = requiresOriginValidation
		}
	}

	public struct ValidatedDappRequest: Sendable, Hashable {
		public let route: P2P.Route
		public let request: Request
		public let requiresOriginVerification: Bool

		public init(route: P2P.Route, request: Request, requiresOriginVerification: Bool) {
			self.route = route
			self.request = request
			self.requiresOriginVerification = requiresOriginVerification
		}

		public enum Request: Sendable, Hashable {
			case valid(DappToWalletInteraction)
			case invalid(request: DappToWalletInteractionUnvalidated, reason: InvalidRequestReason)
		}

		public enum InvalidRequestReason: Sendable, Hashable {
			case incompatibleVersion(connectorExtensionSent: WalletInteractionVersion, walletUses: WalletInteractionVersion)
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
