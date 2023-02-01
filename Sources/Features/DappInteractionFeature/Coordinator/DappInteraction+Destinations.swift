import FeaturePrelude

public extension DappInteraction {
	struct Destinations: ReducerProtocol {
		public enum State: Hashable {
			case login(TempScreen.State)
			case chooseOneTimeAccounts(TempScreen.State)
			//            case chooseOngoingAccounts(TempScreen.State)
		}

		public enum Action: Equatable {
			case login(TempScreen.Action)
			case chooseOneTimeAccounts(TempScreen.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.login, action: /Action.login) {
				TempScreen()
			}
			Scope(state: /State.chooseOneTimeAccounts, action: /Action.chooseOneTimeAccounts) {
				TempScreen()
			}
		}
	}
}
