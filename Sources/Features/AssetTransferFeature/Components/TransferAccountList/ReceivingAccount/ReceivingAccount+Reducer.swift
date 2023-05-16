import FeaturePrelude

// MARK: - ReceivingAccount
public struct ReceivingAccount: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public typealias Account = Profile.Network.Account

		public typealias ID = UUID
		public let id = ID()

		// Either user owned account, or foreign account Address
		public var account: Either<Account, AccountAddress>?
		public var assets: IdentifiedArrayOf<FungibleResourceAsset.State>
		public var canBeRemovedWhenEmpty: Bool

		public struct Asset: Sendable, Hashable, Identifiable {
			public typealias ID = UUID
			public let id = ID()
		}

		@PresentationState
		public var destination: Destinations.State?

		public init(account: Either<Account, AccountAddress>?, assets: IdentifiedArrayOf<FungibleResourceAsset.State>, canBeRemovedWhenEmpty: Bool) {
			self.account = account
			self.assets = assets
			self.canBeRemovedWhenEmpty = canBeRemovedWhenEmpty
		}

		public static func empty(canBeRemovedWhenEmpty: Bool) -> Self {
			.init(account: nil, assets: [], canBeRemovedWhenEmpty: canBeRemovedWhenEmpty)
		}
	}

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case chooseAccount(ChooseAccount.State)
			case addAsset(AddAsset.State)
		}

		public enum Action: Sendable, Equatable {
			case chooseAccount(ChooseAccount.Action)
			case addAsset(AddAsset.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.chooseAccount, action: /Action.chooseAccount) {
				ChooseAccount()
			}

			Scope(state: /State.addAsset, action: /Action.addAsset) {
				AddAsset()
			}
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case chooseAccountTapped
		case addAssetTapped
		case removeTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case removed
	}

	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationAction<Destinations.Action>)
		case row(id: FungibleResourceAsset.State.ID, child: FungibleResourceAsset.Action)
	}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
			.forEach(\.assets, action: /Action.child .. ChildAction.row) {
				FungibleResourceAsset()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .removeTapped:
			return .send(.delegate(.removed))
		case .addAssetTapped:
			state.assets.append(.init(resourceAddress: .init(address: "xrd"), maxAmount: 100))
//			state.destination = .addAsset(.init())
			return .none
		case .chooseAccountTapped:
			state.account = Bool.random() ? .left(.previewValue1) : try! .right(.init(address: "account_tdx_adsadaddadwdadwddwdfadwqdawdwdasdwdasdwd"))
			// state.destination = .chooseAccount(.init())
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .destination(.dismiss):
			return .none
		case let .row(id: id, child: .delegate(.removed)):
			state.assets.remove(id: id)
			return .none
		default:
			return .none
		}
	}
}

extension Either where Left == Profile.Network.Account, Right == AccountAddress {
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
