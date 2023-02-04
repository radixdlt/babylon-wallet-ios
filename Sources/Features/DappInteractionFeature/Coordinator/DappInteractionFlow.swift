import FeaturePrelude

struct DappInteractionFlow: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		typealias Interaction = P2P.FromDapp.WalletInteraction
		typealias AnyInteractionItem = P2P.FromDapp.WalletInteraction.AnyInteractionItem
		typealias AnyInteractionResponseItem = P2P.ToDapp.WalletInteractionSuccessResponse.AnyInteractionResponseItem

		let dappMetadata: DappMetadata
		let interaction: Interaction
		var responses: [AnyInteractionItem: AnyInteractionResponseItem] = [:]

		@NavigationStateOf<Destinations>
		var navigation: NavigationState<Destinations.State>.Path

		init(
			dappMetadata: DappMetadata,
			interaction: Interaction
		) {
			self.dappMetadata = dappMetadata
			self.interaction = interaction
		}
	}

	enum ViewAction: Sendable, Equatable {
		case appeared
	}

	enum ChildAction: Sendable, Equatable {
		case navigation(NavigationActionOf<Destinations>)
	}

	struct Destinations: Sendable, ReducerProtocol {
		enum State: Sendable, Hashable {
			case login(LoginRequest.State)
			case chooseOneTimeAccounts(ChooseAccounts.State)
			case chooseOngoingAccounts(ChooseAccounts.State)
		}

		enum Action: Sendable, Equatable {
			case login(LoginRequest.Action)
			case chooseOneTimeAccounts(ChooseAccounts.Action)
		}

		var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.login, action: /Action.login) {
				LoginRequest()
			}
			Scope(state: /State.chooseOneTimeAccounts, action: /Action.chooseOneTimeAccounts) {
				ChooseAccounts()
			}
		}
	}
}
