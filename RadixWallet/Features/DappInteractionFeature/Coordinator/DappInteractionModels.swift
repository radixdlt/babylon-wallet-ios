import ComposableArchitecture
import SwiftUI

// MARK: - DappInteraction
enum DappInteraction {}

// MARK: - DappMetadata
/// Metadata for a dapp, either from a request or fetched from ledger.
/// not to be confused with `DappToWalletInteractionMetadata` which is the
/// associated value of one of the cases of this enum.
enum DappMetadata: Sendable, Hashable {
	/// The metadata sent with the request from the Dapp.
	/// We only allow this case `request` to be passed around if `isDeveloperModeEnabled` is `true`.
	case request(DappToWalletInteractionMetadata)

	/// A detailed DappMetaData fetched from Ledger.
	case ledger(Ledger)

	case wallet(Wallet)
}

extension DappMetadata {
	static let wallet: Wallet = .init()
	struct Wallet: Sendable, Hashable {
		let origin: DappOrigin = .wallet
		let name: NonEmptyString = "Radix Wallet"
		let description: String? = nil
		let thumbnail: URL? = nil
	}
}

// MARK: DappMetadata.Ledger
extension DappMetadata {
	/// A detailed DappMetaData fetched from Ledger.
	struct Ledger: Sendable, Hashable, Codable {
		static let defaultName = NonEmptyString(rawValue: L10n.DAppRequest.Metadata.unknownName)!

		let origin: DappOrigin

		let dAppDefinintionAddress: DappDefinitionAddress
		let name: NonEmptyString?
		let description: String?
		let thumbnail: URL?

		init(
			origin: DappOrigin,
			dAppDefinintionAddress: DappDefinitionAddress,
			name: NonEmptyString?,
			description: String? = nil,
			thumbnail: URL? = nil
		) {
			self.dAppDefinintionAddress = dAppDefinintionAddress
			self.origin = origin
			self.name = name
			self.thumbnail = thumbnail
			self.description = description
		}
	}
}

extension DappMetadata {
	var origin: DappOrigin {
		switch self {
		case let .ledger(metadata): metadata.origin
		case let .request(metadata): metadata.origin
		case let .wallet(metadata): metadata.origin
		}
	}

	var thumbnail: URL? {
		guard case let .ledger(fromLedgerDappMetadata) = self else {
			return nil
		}
		return fromLedgerDappMetadata.thumbnail
	}

	var onLedger: Ledger? {
		guard case let .ledger(fromLedgerDappMetadata) = self else {
			return nil
		}
		return fromLedgerDappMetadata
	}
}

#if DEBUG
extension DappMetadata {
	static let previewValue: Self = try! .ledger(.init(
		origin: "https://radfi.com",
		dAppDefinintionAddress: .init(validatingAddress: "account_tdx_b_1p95nal0nmrqyl5r4phcspg8ahwnamaduzdd3kaklw3vqeavrwa"),
		name: "Collabo.Fi",
		description: "A very collaby finance dapp",
		thumbnail: nil
	)
	)
}
#endif

// MARK: - DappToWalletInteraction
extension DappToWalletInteraction {
	/// A union type containing all request items allowed in a `WalletInteraction`, for app handling purposes.
	enum AnyInteractionItem: Sendable, Hashable {
		// requests
		case auth(DappToWalletInteractionAuthRequestItem)
		case oneTimeAccounts(DappToWalletInteractionAccountsRequestItem)
		case ongoingAccounts(DappToWalletInteractionAccountsRequestItem)
		case oneTimePersonaData(DappToWalletInteractionPersonaDataRequestItem)
		case ongoingPersonaData(DappToWalletInteractionPersonaDataRequestItem)
		case personaProofOfOwnership(PersonaProofOfOwnership)
		case accountsProofOfOwnership(AccountsProofOfOwnership)

		// transactions
		case submitTransaction(DappToWalletInteractionSendTransactionItem)

		// preAuthorization
		case signSubintent(DappToWalletInteractionSubintentRequestItem)

		var priority: some Comparable {
			switch self {
			// requests
			case .auth:
				0
			case .ongoingAccounts:
				1
			case .ongoingPersonaData:
				2
			case .oneTimeAccounts:
				3
			case .oneTimePersonaData:
				4
			case .personaProofOfOwnership:
				5
			case .accountsProofOfOwnership:
				6
			// transactions
			case .submitTransaction:
				0
			// preAuthorization
			case .signSubintent:
				0
			}
		}
	}

	// NB: keep this logic synced up with the enum above
	// Future reflection metadata capabilities should make this
	// implementation simpler and with no need to keep it manually synced up.
	var erasedItems: [AnyInteractionItem] {
		switch items {
		case let .authorizedRequest(items):
			[
				.auth(items.auth),
				items.oneTimeAccounts.map(AnyInteractionItem.oneTimeAccounts),
				items.ongoingAccounts.map(AnyInteractionItem.ongoingAccounts),
				items.oneTimePersonaData.map(AnyInteractionItem.oneTimePersonaData),
				items.ongoingPersonaData.map(AnyInteractionItem.ongoingPersonaData),
			]
			.compactMap { $0 }
		case let .unauthorizedRequest(items):
			[
				items.oneTimeAccounts.map(AnyInteractionItem.oneTimeAccounts),
				items.oneTimePersonaData.map(AnyInteractionItem.oneTimePersonaData),
			]
			.compactMap { $0 }
			+
			items.proofOfOwnership.splitted
		case let .transaction(items):
			[
				.submitTransaction(items.send),
			]
			.compactMap { $0 }
		case let .preAuthorization(items):
			[
				.signSubintent(items.request),
			]
		}
	}
}

extension DappToWalletInteraction.AnyInteractionItem {
	struct PersonaProofOfOwnership: Sendable, Hashable {
		let challenge: DappToWalletInteractionAuthChallengeNonce
		let identityAddress: IdentityAddress

		init?(_ item: DappToWalletInteractionProofOfOwnershipRequestItem) {
			guard let identityAddress = item.identityAddress else {
				return nil
			}
			self.challenge = item.challenge
			self.identityAddress = identityAddress
		}
	}

	struct AccountsProofOfOwnership: Sendable, Hashable {
		let challenge: DappToWalletInteractionAuthChallengeNonce
		let accountAddresses: [AccountAddress]

		init?(_ item: DappToWalletInteractionProofOfOwnershipRequestItem) {
			guard let accountAddresses = item.accountAddresses, !accountAddresses.isEmpty else {
				return nil
			}
			self.challenge = item.challenge
			self.accountAddresses = accountAddresses
		}
	}
}

// MARK: - WalletToDappInteractionSuccessResponse.AnyInteractionResponseItem
extension WalletToDappInteractionSuccessResponse {
	enum AnyInteractionResponseItem: Sendable, Hashable {
		// request responses
		case auth(WalletToDappInteractionAuthRequestResponseItem)
		case oneTimeAccounts(WalletToDappInteractionAccountsRequestResponseItem)
		case ongoingAccounts(WalletToDappInteractionAccountsRequestResponseItem)
		case oneTimePersonaData(WalletToDappInteractionPersonaDataRequestResponseItem)
		case ongoingPersonaData(WalletToDappInteractionPersonaDataRequestResponseItem)
		case proofOfOwnership(WalletToDappInteractionProofOfOwnershipRequestResponseItem)

		// transaction responses
		case send(WalletToDappInteractionSendTransactionResponseItem)
	}

	init?(
		for interaction: DappToWalletInteraction,
		with items: some Collection<WalletToDappInteractionSuccessResponse.AnyInteractionResponseItem>
	) {
		switch interaction.items {
		case .authorizedRequest, .unauthorizedRequest:
			// NB: variadic generics + native case paths should greatly help to simplify this "picking" logic
			var auth: WalletToDappInteractionAuthRequestResponseItem? = nil
			var oneTimeAccounts: WalletToDappInteractionAccountsRequestResponseItem? = nil
			var ongoingAccounts: WalletToDappInteractionAccountsRequestResponseItem? = nil
			var oneTimePersonaData: WalletToDappInteractionPersonaDataRequestResponseItem? = nil
			var ongoingPersonaData: WalletToDappInteractionPersonaDataRequestResponseItem? = nil
			var proofOfOwnership: WalletToDappInteractionProofOfOwnershipRequestResponseItem? = nil

			for item in items {
				switch item {
				case let .auth(item):
					auth = item
				case let .ongoingAccounts(item):
					ongoingAccounts = item
				case let .ongoingPersonaData(item):
					ongoingPersonaData = item
				case let .oneTimeAccounts(item):
					oneTimeAccounts = item
				case let .oneTimePersonaData(item):
					oneTimePersonaData = item
				case let .proofOfOwnership(item):
					proofOfOwnership = item
				case .send:
					continue
				}
			}

			if let auth {
				self.init(
					interactionId: interaction.interactionId,
					items: .authorizedRequest(
						.init(
							auth: auth,
							ongoingAccounts: ongoingAccounts,
							ongoingPersonaData: ongoingPersonaData,
							oneTimeAccounts: oneTimeAccounts,
							oneTimePersonaData: oneTimePersonaData
						)
					)
				)
			} else {
				self.init(
					interactionId: interaction.interactionId,
					items: .unauthorizedRequest(
						.init(
							oneTimeAccounts: oneTimeAccounts,
							oneTimePersonaData: oneTimePersonaData,
							proofOfOwnership: proofOfOwnership
						)
					)
				)
			}

		case .transaction:
			var send: WalletToDappInteractionSendTransactionResponseItem? = nil
			for item in items {
				switch item {
				case .auth, .ongoingAccounts, .ongoingPersonaData, .oneTimeAccounts, .oneTimePersonaData, .proofOfOwnership:
					continue
				case let .send(item):
					send = item
				}
			}

			// NB: remove this check and the init's optionality when `send` becomes optional (when we introduce more transaction item fields)
			guard let send else {
				return nil
			}

			self.init(
				interactionId: interaction.interactionId,
				items: .transaction(.init(send: send))
			)

		case .preAuthorization:
			fatalError("Implement")
		}
	}
}

private extension DappToWalletInteractionProofOfOwnershipRequestItem? {
	/// From a given `DappToWalletInteractionProofOfOwnershipRequestItem`, we may have up to two
	/// `DappToWalletInteraction.AnyInteractionItem`s: one for prooving `Accounts`, and one for `Persona`.
	var splitted: [DappToWalletInteraction.AnyInteractionItem] {
		guard let self else {
			return []
		}
		var result: [DappToWalletInteraction.AnyInteractionItem] = []
		if let persona = DappToWalletInteraction.AnyInteractionItem.PersonaProofOfOwnership(self) {
			result.append(.personaProofOfOwnership(persona))
		}
		if let accounts = DappToWalletInteraction.AnyInteractionItem.AccountsProofOfOwnership(self) {
			result.append(.accountsProofOfOwnership(accounts))
		}
		return result
	}
}
