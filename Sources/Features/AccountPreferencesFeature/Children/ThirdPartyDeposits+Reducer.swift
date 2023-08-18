import AccountsClient
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

		init(account: Profile.Network.Account) {
			self.account = account
		}
	}

	public enum ViewAction: Equatable {
		case updateTapped
		case rowTapped(ThirdPartyDeposits.State.RowKind)
	}

	public enum DelegateAction: Equatable {
		case accountUpdated
	}

	@Dependency(\.accountsClient) var accountsClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.overlayWindowClient) var overlayWindowClient

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case let .rowTapped(row):
			switch row {
			case .depositMode(.acceptAll):
				state.depositMode = .acceptAll
			case .depositMode(.acceptKnown):
				state.depositMode = .acceptKnown
			case .depositMode(.denyAll):
				state.depositMode = .denyAll
			case .allowDenyResources:
				// navigate
				return .none
			}
			return .none
		case .updateTapped:
			return .none
		}
	}
}
