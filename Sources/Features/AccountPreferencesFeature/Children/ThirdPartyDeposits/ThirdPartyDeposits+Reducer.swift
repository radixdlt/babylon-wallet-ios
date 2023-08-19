import AccountsClient
import EngineKit
import FeaturePrelude
import OverlayWindowClient

// MARK: - UpdateAccountLabel
public struct ThirdPartyDeposits: FeatureReducer {
	public struct State: Hashable, Sendable {
		public enum ThirdPartyDepositMode: Hashable, Sendable {
			case acceptAll
			case acceptKnown
			case denyAll
		}

		var account: Profile.Network.Account
		// TODO: should be derived/extracted from account
		var depositMode: ThirdPartyDepositMode = .acceptAll

		@PresentationState
		var destinations: Destinations.State? = nil

		init(account: Profile.Network.Account) {
			self.account = account
		}
	}

	public enum ViewAction: Equatable {
		case updateTapped
		case rowTapped(ThirdPartyDeposits.Section.Row)
	}

	public enum DelegateAction: Equatable {
		case accountUpdated
	}

	public enum ChildAction: Sendable, Equatable {
		case destinations(PresentationAction<Destinations.Action>)
	}

	public struct Destinations: ReducerProtocol {
		public enum State: Equatable, Hashable {
			case allowDenyAssets(AllowDenyAssets.State)
		}

		public enum Action: Equatable {
			case allowDenyAssets(AllowDenyAssets.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.allowDenyAssets, action: /Action.allowDenyAssets) {
				AllowDenyAssets()
			}
		}
	}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$destinations, action: /Action.child .. ChildAction.destinations) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case let .rowTapped(row):
			switch row {
			case .depositsMode(.acceptAll):
				state.depositMode = .acceptAll
			case .depositsMode(.acceptKnown):
				state.depositMode = .acceptKnown
			case .depositsMode(.denyAll):
				state.depositMode = .denyAll
			case .allowDenyAssets:
				state.destinations = .allowDenyAssets(.init(list: .allow))
				return .none
			case .allowDepositors:
				return .none
			}
			return .none
		case .updateTapped:
			return .none
		}
	}
}
