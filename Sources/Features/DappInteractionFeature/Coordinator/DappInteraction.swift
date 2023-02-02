import FeaturePrelude

public struct DappInteraction: Sendable, FeatureReducer {
	public struct State: Sendable, Equatable {
		let interaction: P2P.FromDapp.WalletInteraction

		@NavigationStateOf<Destinations>
		var navigation: NavigationState<Destinations.State>.Path

		public init(
			interaction: P2P.FromDapp.WalletInteraction
		) {
			self.interaction = interaction
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
	}

	public enum ChildAction: Sendable, Equatable {
		case navigation(NavigationActionOf<Destinations>)
	}

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case login(LoginRequest.State)
			case chooseOneTimeAccounts(ChooseAccounts.State)
//			case chooseOngoingAccounts(TempScreen.State)
		}

		public enum Action: Sendable, Equatable {
			case login(LoginRequest.Action)
			case chooseOneTimeAccounts(ChooseAccounts.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.login, action: /Action.login) {
				LoginRequest()
			}
			Scope(state: /State.chooseOneTimeAccounts, action: /Action.chooseOneTimeAccounts) {
				ChooseAccounts()
			}
		}
	}

	public init() {}
}
