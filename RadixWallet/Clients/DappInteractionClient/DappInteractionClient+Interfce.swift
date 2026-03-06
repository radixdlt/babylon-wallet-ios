// MARK: - DappInteractionClient
struct DappInteractionClient {
	let interactions: AnyAsyncSequence<Result<ValidatedDappRequest, Error>>
	let addWalletInteraction: AddWalletInteraction
	let completeInteraction: CompleteInteraction
}

extension DappInteractionClient {
	enum WalletInteraction: String, Hashable {
		case accountDepositSettings
		case accountTransfer
		case accountLockerClaim
		case accountDelete
		case shieldUpdate
		case rawManifestTransaction
	}

	/// Result of a wallet interaction containing both P2P response (for external dApps)
	/// and internal data (for wallet-initiated interactions)
	struct WalletInteractionResult: Hashable {
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

	var isWalletRawManifestTransactionInteraction: Bool {
		hasPrefix(DappInteractionClient.WalletInteraction.rawManifestTransaction.rawValue)
	}

	var isWalletInteraction: Bool {
		isWalletAccountTransferInteraction
			|| isWalletAccountDepositSettingsInteraction
			|| isWalletAccountLockerClaimInteraction
			|| isWalletAccountDeleteInteraction
			|| isWalletShieldUpdateInteraction
			|| isWalletRawManifestTransactionInteraction
	}
}

extension DappInteractionClient {
	struct RequestEnvelope: Hashable {
		let route: P2P.Route
		let interaction: DappToWalletInteraction
		let requiresOriginValidation: Bool

		init(route: P2P.Route, interaction: DappToWalletInteraction, requiresOriginValidation: Bool) {
			self.route = route
			self.interaction = interaction
			self.requiresOriginValidation = requiresOriginValidation
		}
	}

	struct ValidatedDappRequest: Hashable {
		let route: P2P.Route
		let request: Request
		let requiresOriginVerification: Bool

		init(route: P2P.Route, request: Request, requiresOriginVerification: Bool) {
			self.route = route
			self.request = request
			self.requiresOriginVerification = requiresOriginVerification
		}

		enum Request: Hashable {
			case valid(DappToWalletInteraction)
			case invalid(request: DappToWalletInteractionUnvalidated, reason: InvalidRequestReason)
		}

		enum InvalidRequestReason: Hashable {
			case incompatibleVersion(connectorExtensionSent: WalletInteractionVersion, walletUses: WalletInteractionVersion)
			case wrongNetworkID(connectorExtensionSent: NetworkID, walletUses: NetworkID)
			case invalidDappDefinitionAddress(gotStringWhichIsAnInvalidAccountAddress: String)
			case invalidOrigin(invalidURLString: String)
			case dAppValidationError(String)
			case badContent(BadContent)
			case invalidPersonaOrAccounts
			case invalidPreAuthorization(InvalidPreAuthorization)

			enum BadContent: Hashable {
				case numberOfAccountsInvalid
			}

			enum InvalidPreAuthorization: Hashable {
				case expirationTooClose
				case expired
			}
		}
	}
}
