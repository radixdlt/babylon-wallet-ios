import ComposableArchitecture
import SwiftUI

// MARK: - AccountPreferences
public struct AccountPreferences: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var account: Profile.Network.Account

		@PresentationState
		var destinations: Destinations.State? = nil

		public init(account: Profile.Network.Account) {
			self.account = account
		}
	}

	// MARK: - Action

	public enum ViewAction: Sendable, Equatable {
		case task
		case qrCodeButtonTapped
		case rowTapped(AccountPreferences.Section.SectionRow)
	}

	public enum InternalAction: Sendable, Equatable {
		case accountUpdated(Profile.Network.Account)
	}

	public enum ChildAction: Sendable, Equatable {
		case destinations(PresentationAction<Destinations.Action>)
	}

	// MARK: - Destination
	public struct Destinations: Reducer, Sendable {
		public enum State: Equatable, Hashable {
			case showQR(ShowQR.State)
			case updateAccountLabel(UpdateAccountLabel.State)
			case thirdPartyDeposits(ManageThirdPartyDeposits.State)
			case devPreferences(DevAccountPreferences.State)
		}

		public enum Action: Equatable, Sendable {
			case showQR(ShowQR.Action)
			case updateAccountLabel(UpdateAccountLabel.Action)
			case thirdPartyDeposits(ManageThirdPartyDeposits.Action)
			case devPreferences(DevAccountPreferences.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.showQR, action: /Action.showQR) {
				ShowQR()
			}
			Scope(state: /State.updateAccountLabel, action: /Action.updateAccountLabel) {
				UpdateAccountLabel()
			}
			Scope(state: /State.thirdPartyDeposits, action: /Action.thirdPartyDeposits) {
				ManageThirdPartyDeposits()
			}
			Scope(state: /State.devPreferences, action: /Action.devPreferences) {
				DevAccountPreferences()
			}
		}
	}

	@Dependency(\.accountsClient) var accountsClient

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(\.$destinations, action: /Action.child .. ChildAction.destinations) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			return .run { [address = state.account.address] send in
				for try await accountUpdate in await accountsClient.accountUpdates(address) {
					guard !Task.isCancelled else { return }
					await send(.internal(.accountUpdated(accountUpdate)))
				}
			}

		case .qrCodeButtonTapped:
			state.destinations = .showQR(.init(accountAddress: state.account.address))
			return .none

		case let .rowTapped(row):
			return destination(for: row, &state)
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .destinations(.presented(action)):
			onDestinationAction(action, &state)
		default:
			.none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .accountUpdated(updated):
			state.account = updated
			return .none
		}
	}
}

extension AccountPreferences {
	func destination(for row: AccountPreferences.Section.SectionRow, _ state: inout State) -> Effect<Action> {
		switch row {
		case .personalize(.accountLabel):
			state.destinations = .updateAccountLabel(.init(account: state.account))
			return .none

		case .personalize(.accountColor):
			return .none

		case .personalize(.tags):
			return .none

		case .onLedger(.thirdPartyDeposits):
			state.destinations = .thirdPartyDeposits(.init(account: state.account))
			return .none

		case .onLedger(.accountSecurity):
			return .none

		case .dev(.devPreferences):
			state.destinations = .devPreferences(.init(address: state.account.address))
			return .none
		}
	}

	func onDestinationAction(_ action: AccountPreferences.Destinations.Action, _ state: inout State) -> Effect<Action> {
		switch action {
		case .showQR(.delegate(.dismiss)):
			if case .showQR = state.destinations {
				state.destinations = nil
			}
			return .none
		case .showQR:
			return .none
		case .updateAccountLabel(.delegate(.accountLabelUpdated)),
		     .thirdPartyDeposits(.delegate(.accountUpdated)):
			state.destinations = nil
			return .none
		case .updateAccountLabel:
			return .none
		case .thirdPartyDeposits:
			return .none
		case .devPreferences:
			return .none
		}
	}
}
