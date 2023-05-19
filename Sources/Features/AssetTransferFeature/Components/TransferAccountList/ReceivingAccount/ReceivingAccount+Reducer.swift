import FeaturePrelude

// MARK: - ReceivingAccount
public struct ReceivingAccount: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public typealias Account = Profile.Network.Account

		public typealias ID = UUID
		public let id = ID()

		// Either user owned account, or foreign account Address
		public var account: Either<Account, AccountAddress>?
		public var assets: IdentifiedArrayOf<ResourceAsset.State>
		public var canBeRemoved: Bool

		public struct Asset: Sendable, Hashable, Identifiable {
			public typealias ID = UUID
			public let id = ID()
		}

		@PresentationState
		public var destination: Destinations.State?

		public init(
			account: Either<Account, AccountAddress>?,
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
		case validate
		case remove
	}

	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationAction<Destinations.Action>)
		case row(id: ResourceAsset.State.ID, child: ResourceAsset.Action)
	}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
			.forEach(\.assets, action: /Action.child .. ChildAction.row) {
				ResourceAsset()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .removeTapped:
			return .send(.delegate(.remove))
		case .addAssetTapped:
			state.destination = .addAsset(.init())
			return .none
		case .chooseAccountTapped:
			state.destination = .chooseAccount(.init())
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .destination(.presented(action)):
			switch action {
			case let .chooseAccount(.delegate(.addOwnedAccount(account))):
				state.account = .left(account)
				return .send(.delegate(.validate))
			case let .chooseAccount(.delegate(.addExternalAccount(address))):
				state.account = .right(address)
				return .send(.delegate(.validate))
			case let .addAsset(.delegate(.addFungibleResource(resource, isXRD))):
				state.assets.append(.fungibleAsset(.init(resource: resource, isXRD: isXRD, totalTransferSum: .zero)))
				return .send(.delegate(.validate))

			case let .addAsset(.delegate(.addNonFungibleResource(resourceAddress, token))):
				state.assets.append(.nonFungibleAsset(.init(resourceAddress: resourceAddress, nftToken: token)))
				return .send(.delegate(.validate))
			}

		case let .row(id: id, child: .delegate(.removed)):
			state.assets.remove(id: id)
			return .send(.delegate(.validate))

		case .destination(.dismiss):
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
