import ComposableArchitecture
import FeaturePrelude

// MARK: - TransactionReviewAccount
public struct TransactionReviewAccount: Sendable, FeatureReducer {
	@Dependency(\.pasteboardClient) private var pasteboardClient

	public struct State: Sendable, Identifiable, Hashable {
		public var id: AccountAddress.ID { account.address.id }
		public let account: Account
		public let details: [Details]

		public enum Account: Sendable, Hashable {
			case user(OnNetwork.AccountForDisplay)
			case external(AccountAddress, approved: Bool)

			var address: AccountAddress {
				switch self {
				case let .user(account):
					return account.address
				case let .external(address, _):
					return address
				}
			}
		}

		public init(account: Account, details: [Details]) {
			self.account = account
			self.details = details
		}

		public struct Details: Sendable, Hashable {
			public let metadata: Metadata?
			public let transferred: Transferred

			public init(metadata: Metadata?, transferred: Transferred) {
				self.metadata = metadata
				self.transferred = transferred
			}

			public struct Metadata: Sendable, Hashable {
				public let name: String
				public let thumbnail: URL

				public init(name: String, thumbnail: URL) {
					self.name = name
					self.thumbnail = thumbnail
				}
			}

			public enum Transferred: Sendable, Hashable {
				case nft
				case token(BigDecimal, guaranteed: BigDecimal?, dollars: BigDecimal?)
			}
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case copyAddress
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .none
		case .copyAddress:
			print("Account copyAddress")
			pasteboardClient.copyString(state.account.address.address)
			return .none
		}
	}
}
