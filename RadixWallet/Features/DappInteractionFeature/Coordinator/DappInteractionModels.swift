import ComposableArchitecture
import SwiftUI

// MARK: - DappInteraction
enum DappInteraction {}

// MARK: - DappMetadata
// extension DappInteraction {
//	typealias NumberOfAccounts = P2P.Dapp.Request.NumberOfAccounts
// }

/// Metadata for a dapp, either from a request or fetched from ledger.
/// not to be confused with `DappToWalletInteractionMetadata` which is the
/// associated value of one of the cases of this enum.
public enum DappMetadata: Sendable, Hashable {
	/// The metadata sent with the request from the Dapp.
	/// We only allow this case `request` to be passed around if `isDeveloperModeEnabled` is `true`.
	case request(DappToWalletInteractionMetadata)

	/// A detailed DappMetaData fetched from Ledger.
	case ledger(Ledger)

	case wallet(Wallet)

	case deepLink(DeepLink)
}

// MARK: DappMetadata.DeepLink
extension DappMetadata {
	public struct DeepLink: Sendable, Hashable {
		public let origin: URL
		public let dAppDefAddress: DappDefinitionAddress
	}
}

extension DappMetadata {
	static let wallet: Wallet = .init()
	public struct Wallet: Sendable, Hashable {
		let origin: DappToWalletInteractionMetadata.Origin = .wallet
		let name: NonEmptyString = "Radix Wallet"
		let description: String? = nil
		let thumbnail: URL? = nil
	}
}

// MARK: DappMetadata.Ledger
extension DappMetadata {
	/// A detailed DappMetaData fetched from Ledger.
	public struct Ledger: Sendable, Hashable, Codable {
		static let defaultName = NonEmptyString(rawValue: L10n.DAppRequest.Metadata.unknownName)!

		let origin: DappToWalletInteractionMetadata.Origin

		let dAppDefinintionAddress: DappDefinitionAddress
		let name: NonEmptyString?
		let description: String?
		let thumbnail: URL?

		init(
			origin: DappToWalletInteractionMetadata.Origin,
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
	public var origin: DappToWalletInteractionMetadata.Origin {
		switch self {
		case let .ledger(metadata): metadata.origin
		case let .request(metadata): metadata.origin
		case let .wallet(metadata): metadata.origin
		case let .deepLink(metadata): try! .init(string: metadata.origin.absoluteString)
		}
	}

	public var thumbnail: URL? {
		guard case let .ledger(fromLedgerDappMetadata) = self else {
			return nil
		}
		return fromLedgerDappMetadata.thumbnail
	}

	public var onLedger: Ledger? {
		guard case let .ledger(fromLedgerDappMetadata) = self else {
			return nil
		}
		return fromLedgerDappMetadata
	}
}

#if DEBUG
extension DappMetadata {
	static let previewValue: Self = try! .ledger(.init(
		origin: .wallet, // .init(string: "https://radfi.com"),
		dAppDefinintionAddress: .init(validatingAddress: "account_tdx_b_1p95nal0nmrqyl5r4phcspg8ahwnamaduzdd3kaklw3vqeavrwa"),
		name: "Collabo.Fi",
		description: "A very collaby finance dapp",
		thumbnail: nil
	)
	)
}
#endif

// MARK: - P2P.Dapp.Request.WalletRequestItem
extension DappToWalletInteraction {
	/// A union type containing all request items allowed in a `WalletInteraction`, for app handling purposes.
	enum AnyInteractionItem: Sendable, Hashable {
		// requests
		case auth(DappToWalletInteractionAuthRequestItem)
		case oneTimeAccounts(DappToWalletInteractionAccountsRequestItem)
		case ongoingAccounts(DappToWalletInteractionAccountsRequestItem)
		case oneTimePersonaData(DappToWalletInteractionPersonaDataRequestItem)
		case ongoingPersonaData(DappToWalletInteractionPersonaDataRequestItem)

		// transactions
		case send(DappToWalletInteractionSendTransactionItem)

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

			// transactions
			case .send:
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
		case let .transaction(items):
			[
				.send(items.send),
			]
			.compactMap { $0 }
		}
	}
}

// MARK: - P2P.Dapp.Response.WalletInteractionSuccessResponse.AnyInteractionResponseItem
extension WalletToDappInteractionSuccessResponse {
	enum AnyInteractionResponseItem: Sendable, Hashable {
		// request responses
		case auth(WalletToDappInteractionAuthRequestResponseItem)
		case oneTimeAccounts(WalletToDappInteractionAccountsRequestResponseItem)
		case ongoingAccounts(WalletToDappInteractionAccountsRequestResponseItem)
		case oneTimePersonaData(WalletToDappInteractionPersonaDataRequestResponseItem)
		case ongoingPersonaData(WalletToDappInteractionPersonaDataRequestResponseItem)

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
							oneTimePersonaData: oneTimePersonaData
						)
					)
				)
			}

		case .transaction:
			var send: WalletToDappInteractionSendTransactionResponseItem? = nil
			for item in items {
				switch item {
				case .auth, .ongoingAccounts, .ongoingPersonaData, .oneTimeAccounts, .oneTimePersonaData:
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
		}
	}
}
