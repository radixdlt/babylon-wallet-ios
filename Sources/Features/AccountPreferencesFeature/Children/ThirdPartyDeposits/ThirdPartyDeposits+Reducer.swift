import AccountsClient
import EngineKit
import FeaturePrelude
import OverlayWindowClient

public typealias ThirdPartyDeposits = Profile.Network.Account.OnLedgerSettings.ThirdPartyDeposits

// MARK: - ManageThirdPartyDeposits
public struct ManageThirdPartyDeposits: FeatureReducer {
	public struct State: Hashable, Sendable {
		var account: Profile.Network.Account

		var depositRule: ThirdPartyDeposits.DepositRule {
			account.onLedgerSettings.thirdPartyDeposits.depositRule
		}

		@PresentationState
		var destinations: Destinations.State? = nil

		init(account: Profile.Network.Account) {
			self.account = account
		}
	}

	public enum ViewAction: Equatable {
		case updateTapped
		case rowTapped(ManageThirdPartyDeposits.Section.Row)
	}

	public enum DelegateAction: Equatable {
		case accountUpdated
	}

	public enum ChildAction: Sendable, Equatable {
		case destinations(PresentationAction<Destinations.Action>)
	}

	public struct Destinations: ReducerProtocol {
		public enum State: Equatable, Hashable {
			case allowDenyAssets(ResourcesList.State)
			case allowDepositors(ResourcesList.State)
		}

		public enum Action: Equatable {
			case allowDenyAssets(ResourcesList.Action)
			case allowDepositors(ResourcesList.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.allowDenyAssets, action: /Action.allowDenyAssets) {
				ResourcesList()
			}

			Scope(state: /State.allowDepositors, action: /Action.allowDepositors) {
				ResourcesList()
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
			case let .depositRule(rule):
				state.account.onLedgerSettings.thirdPartyDeposits.depositRule = rule
			case .allowDenyAssets:
				state.destinations = .allowDenyAssets(.init(
					mode: .allowDenyAssets(.allow),
					thirdPartyDeposits: state.account.onLedgerSettings.thirdPartyDeposits,
					resources: []
				))
			case .allowDepositors:
				state.destinations = .allowDepositors(.init(
					mode: .allowDepositors,
					thirdPartyDeposits: state.account.onLedgerSettings.thirdPartyDeposits,
					resources: []
				))
			}
			return .none
		case .updateTapped:
			@Dependency(\.accountsClient) var accountsClient
			@Dependency(\.errorQueue) var errorQueue

			return .run { [account = state.account] send in
				do {
					try await accountsClient.updateAccount(account)
					// schedule tx
					await send(.delegate(.accountUpdated))
				} catch {
					errorQueue.schedule(error)
				}
			}
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .destinations(.presented(.allowDenyAssets(.delegate(.updated(thirdPartyDeposits))))),
		     let .destinations(.presented(.allowDepositors(.delegate(.updated(thirdPartyDeposits))))):
			state.account.onLedgerSettings.thirdPartyDeposits = thirdPartyDeposits
			return .none
		case .destinations:
			return .none
		}
	}
}
