import AccountsClient
import FeaturePrelude

// MARK: - AccountPreferences
public struct AccountPreferences: Sendable, FeatureReducer {
	// MARK: - State

	public struct State: Sendable, Hashable {
		public var account: Profile.Network.Account

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
		case task
		case rowTapped(AccountPreferences.Section.SectionRow)
	}

	public enum InternalAction: Sendable, Equatable {
		case accountUpdated(Profile.Network.Account)
	}

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
			case thirdPartyDeposits(ThirdPartyDeposits.State)
			case devPreferences(DevAccountPreferences.State)
		}

		public enum Action: Equatable {
			case updateAccountLabel(UpdateAccountLabel.Action)
			case thirdPartyDeposits(ThirdPartyDeposits.Action)
			case devPreferences(DevAccountPreferences.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.updateAccountLabel, action: /Action.updateAccountLabel) {
				UpdateAccountLabel()
			}
			Scope(state: /State.thirdPartyDeposits, action: /Action.thirdPartyDeposits) {
				ThirdPartyDeposits()
			}
			Scope(state: /State.devPreferences, action: /Action.devPreferences) {
				DevAccountPreferences()
			}
		}
	}

	@Dependency(\.accountsClient) var accountsClient

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$destinations, action: /Action.child .. ChildAction.destinations) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .task:
			return .run { [address = state.account.address] send in
				for try await accountUpdate in await accountsClient.accountUpdates(address) {
					guard !Task.isCancelled else { return }
					await send(.internal(.accountUpdated(accountUpdate)))
				}
			}

		case .rowTapped(.personalize(.accountLabel)):
			state.destinations = .updateAccountLabel(.init(account: state.account))
			return .none

		case .rowTapped(.dev(.devPreferences)):
			state.destinations = .devPreferences(.init(address: state.account.address))
			return .none

		case .rowTapped(.onLedger(.thirdPartyDeposits)):
			state.destinations = .thirdPartyDeposits(.init(account: state.account))
			return .none

		case .rowTapped:
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .destinations(.presented(action)):
			switch action {
			case .updateAccountLabel(.delegate(.accountLabelUpdated)):
				state.destinations = nil
				return .none
			case .updateAccountLabel:
				return .none
			case .thirdPartyDeposits:
				return .none
			case .devPreferences:
				return .none
			}

		default:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .accountUpdated(updated):
			state.account = updated
			return .none
		}
	}
}
