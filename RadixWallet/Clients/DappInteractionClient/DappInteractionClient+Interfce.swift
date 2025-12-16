// MARK: - DappInteractionClient
struct DappInteractionClient: Sendable {
	let interactions: AnyAsyncSequence<Result<ValidatedDappRequest, Error>>
	let addWalletInteraction: AddWalletInteraction
	let completeInteraction: CompleteInteraction

	init(
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
	enum WalletInteraction: String, Sendable, Hashable {
		case accountDepositSettings
		case accountTransfer
		case accountLockerClaim
		case accountDelete
		case shieldUpdate
	}

	/// Result of a wallet interaction containing both P2P response (for external dApps)
	/// and internal data (for wallet-initiated interactions)
	struct WalletInteractionResult: Sendable, Hashable {
		/// The P2P response sent to external dApps
		let p2pResponse: P2P.RTCOutgoingMessage.Response
		/// The notarized transaction (populated for transaction interactions)
		let notarizedTransaction: NotarizedTransaction?

		init(
			p2pResponse: P2P.RTCOutgoingMessage.Response,
			notarizedTransaction: NotarizedTransaction? = nil
		) {
			self.p2pResponse = p2pResponse
			self.notarizedTransaction = notarizedTransaction
		}
	}

	typealias AddWalletInteraction = @Sendable (_ items: DappToWalletInteractionItems, _ interaction: WalletInteraction) async -> WalletInteractionResult
	typealias CompleteInteraction = @Sendable (P2P.RTCOutgoingMessage, _ notarizedTransaction: NotarizedTransaction?) async throws -> Void
}

extension WalletInteractionId {
	static func walletInteractionID(for interaction: DappInteractionClient.WalletInteraction) -> Self {
		"\(interaction.rawValue)_\(UUID().uuidString)"
	}

	var isWalletAccountDepositSettingsInteraction: Bool {
		hasPrefix(DappInteractionClient.WalletInteraction.accountDepositSettings.rawValue)
	}

	var isWalletAccountTransferInteraction: Bool {
		hasPrefix(DappInteractionClient.WalletInteraction.accountTransfer.rawValue)
	}

	var isWalletAccountLockerClaimInteraction: Bool {
		hasPrefix(DappInteractionClient.WalletInteraction.accountLockerClaim.rawValue)
	}

	var isWalletAccountDeleteInteraction: Bool {
		hasPrefix(DappInteractionClient.WalletInteraction.accountDelete.rawValue)
	}

	var isWalletShieldUpdateInteraction: Bool {
		hasPrefix(DappInteractionClient.WalletInteraction.shieldUpdate.rawValue)
	}

	var isWalletInteraction: Bool {
		isWalletAccountTransferInteraction
			|| isWalletAccountDepositSettingsInteraction
			|| isWalletAccountLockerClaimInteraction
			|| isWalletAccountDeleteInteraction
			|| isWalletShieldUpdateInteraction
	}
}

extension DappInteractionClient {
	struct RequestEnvelope: Sendable, Hashable {
		let route: P2P.Route
		let interaction: DappToWalletInteraction
		let requiresOriginValidation: Bool

		init(route: P2P.Route, interaction: DappToWalletInteraction, requiresOriginValidation: Bool) {
			self.route = route
			self.interaction = interaction
			self.requiresOriginValidation = requiresOriginValidation
		}
	}

	struct ValidatedDappRequest: Sendable, Hashable {
		let route: P2P.Route
		let request: Request
		let requiresOriginVerification: Bool

		init(route: P2P.Route, request: Request, requiresOriginVerification: Bool) {
			self.route = route
			self.request = request
			self.requiresOriginVerification = requiresOriginVerification
		}

		enum Request: Sendable, Hashable {
			case valid(DappToWalletInteraction)
			case invalid(request: DappToWalletInteractionUnvalidated, reason: InvalidRequestReason)
		}

		enum InvalidRequestReason: Sendable, Hashable {
			case incompatibleVersion(connectorExtensionSent: WalletInteractionVersion, walletUses: WalletInteractionVersion)
			case wrongNetworkID(connectorExtensionSent: NetworkID, walletUses: NetworkID)
			case invalidDappDefinitionAddress(gotStringWhichIsAnInvalidAccountAddress: String)
			case invalidOrigin(invalidURLString: String)
			case dAppValidationError(String)
			case badContent(BadContent)
			case invalidPersonaOrAccounts
			case invalidPreAuthorization(InvalidPreAuthorization)

			enum BadContent: Sendable, Hashable {
				case numberOfAccountsInvalid
			}

			enum InvalidPreAuthorization: Sendable, Hashable {
				case expirationTooClose
				case expired
			}
		}
	}
}
