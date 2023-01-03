import ComposableArchitecture
import PasteboardClient

// MARK: - AccountList
public struct AccountList: Sendable, ReducerProtocol {
	@Dependency(\.pasteboardClient) var pasteboardClient

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce { state, action in
			switch action {
			case .delegate:
				return .none

			// FIXME: this logic belongs to the child instead, as only delegates should be intercepted via .child
			// and every other action should fall-through - @davdroman-rdx
			case let .child(.account(id: id, action: action)):
				guard let account = state.accounts[id: id] else {
					assertionFailure("Account value should not be nil.")
					return .none
				}
				switch action {
				case .internal(.view(.copyAddressButtonTapped)):
					let address = account.address.address
					return .fireAndForget { pasteboardClient.copyString(address) }
				case .internal(.view(.selected)):
					return .run { send in
						await send(.delegate(.displayAccountDetails(account)))
					}
				}

			case .internal(.view(.alertDismissButtonTapped)):
				state.alert = nil
				return .none

			case .internal(.view(.viewAppeared)):
				return .run { send in
					await send(.delegate(.fetchPortfolioForAccounts))
				}
			}
		}
		.forEach(\.accounts, action: /Action.child .. Action.ChildAction.account) {
			AccountList.Row()
		}
	}
}
