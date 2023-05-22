import FeaturePrelude

// MARK: - ReceivingAccount
public struct ReceivingAccount: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public typealias OwnedAccount = Profile.Network.Account
		public typealias Account = Either<OwnedAccount, AccountAddress>

		public typealias ID = UUID
		public let id = ID()

		// Either user owned account, or foreign account Address
		public var account: Account?
		public var assets: IdentifiedArrayOf<ResourceAsset.State>
		public var canBeRemoved: Bool

		public struct Asset: Sendable, Hashable, Identifiable {
			public typealias ID = UUID
			public let id = ID()
		}

		public init(
			account: Account?,
			assets: IdentifiedArrayOf<ResourceAsset.State>,
			canBeRemovedWhenEmpty: Bool
		) {
			self.account = account
			self.assets = assets
			self.canBeRemoved = canBeRemovedWhenEmpty
		}

		public static func empty(canBeRemovedWhenEmpty: Bool) -> Self {
			.init(account: nil, assets: [], canBeRemovedWhenEmpty: canBeRemovedWhenEmpty)
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case chooseAccountTapped
		case addAssetTapped
		case removeTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case validate
		case remove
		case chooseAccount
		case addAssets
	}

	public enum ChildAction: Sendable, Equatable {
		case row(id: ResourceAsset.State.ID, child: ResourceAsset.Action)
	}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.forEach(\.assets, action: /Action.child .. ChildAction.row) {
				ResourceAsset()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .removeTapped:
			return .send(.delegate(.remove))
		case .addAssetTapped:
			return .send(.delegate(.addAssets))
		case .chooseAccountTapped:
			return .send(.delegate(.chooseAccount))
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .row(id: id, child: .delegate(.removed)):
			state.assets.remove(id: id)
			return .send(.delegate(.validate))
		default:
			return .none
		}
	}
}

extension ReceivingAccount.State.Account {
	var name: String {
		switch self {
		case let .left(account):
			return account.displayName.rawValue
		case .right:
			return "Account"
		}
	}

	var identifer: LedgerIdentifiable {
		switch self {
		case let .left(account):
			return .address(.account(account.address))
		case let .right(address):
			return .address(.account(address))
		}
	}

	var gradient: Gradient {
		switch self {
		case let .left(account):
			return .init(account.appearanceID)
		case .right:
			return .init(colors: [.app.gray2])
		}
	}
}
