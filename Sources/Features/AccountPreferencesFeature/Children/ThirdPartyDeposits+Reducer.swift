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
		case rowTapped(ThirdPartyDeposits.Section.Row)
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
			case .depositsMode(.acceptAll):
				state.depositMode = .acceptAll
			case .depositsMode(.acceptKnown):
				state.depositMode = .acceptKnown
			case .depositsMode(.denyAll):
				state.depositMode = .denyAll
			case .allowDenyAssets:
				// navigate
				return .none
			}
			return .none
		case .updateTapped:
			return .none
		}
	}
}
