import FeaturePrelude

public struct ToAccountTransfer: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public typealias Account = Profile.Network.Account

		public typealias ID = UUID
		public let id = ID()

		// Either user owned account, or foreign account Address
		public var account: Either<Account, AccountAddress>?
		public var assets: [String] // Just string for now as a placeholder

		@PresentationState
		public var destination: Destinations.State?

		public init(account: Either<Account, AccountAddress>?, assets: [String]) {
			self.account = account
			self.assets = assets
		}

		public static var empty: Self {
			.init(account: nil, assets: [])
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
	}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .removeTapped:
			return .send(.delegate(.removed))
		case .addAssetTapped:
			state.destination = .addAsset(.init())
			return .none
		case .chooseAccountTapped:
			state.destination = .chooseAccount(.init())
			return .none
		}
	}
}
