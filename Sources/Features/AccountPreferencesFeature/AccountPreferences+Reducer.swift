import AccountPortfoliosClient
import AccountsClient
import CreateAuthKeyFeature
import EngineKit
import FaucetClient
import FeaturePrelude
import GatewayAPI
import ShowQRFeature

#if DEBUG
// Manifest turning account into Dapp Definition type, debug action...
import TransactionReviewFeature
#endif // DEBUG

// MARK: - AccountPreferences
public struct AccountPreferences: Sendable, FeatureReducer {
	// MARK: - State

	public struct State: Sendable, Hashable {
		public let account: Profile.Network.Account

		@PresentationState
		var destinations: Destinations.State? = nil

		public init(
			account: Profile.Network.Account
		) {
			self.account = account
		}
	}

	// MARK: - Action

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case rowTapped(AccountPreferences.Section.Row.Kind)
	}

	public enum InternalAction: Sendable, Equatable {}

	public enum ChildAction: Sendable, Equatable {
		case destinations(PresentationAction<Destinations.Action>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismiss
	}

	// MARK: - Destination

	public struct Destinations: ReducerProtocol {
		public enum State: Equatable, Hashable {
			case updateAccountLabel(UpdateAccountLabel.State)
		}

		public enum Action: Equatable {
			case updateAccountLabel(UpdateAccountLabel.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.updateAccountLabel, action: /Action.updateAccountLabel) {
				UpdateAccountLabel()
			}
		}
	}

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$destinations, action: /Action.child .. ChildAction.destinations) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .rowTapped(.accountLabel):
			state.destinations = .updateAccountLabel(.init(accountLabel: state.account.displayName.rawValue))
			return .none
		case .appeared:
			return .none
		default:
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .destinations(.presented(action)):
			switch action {
			default:
				return .none
			}

		default:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		.none
	}
}
