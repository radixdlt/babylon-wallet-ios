import AssetsViewFeature
import AssetTransferFeature
import FeaturePrelude

// MARK: - AccountDetails
public struct AccountDetails: Sendable, ReducerProtocol {
	@Dependency(\.pasteboardClient) var pasteboardClient

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.assets, action: /Action.child .. Action.ChildAction.assets) {
			AssetsView()
		}

		CaseReduce(core, case: /Action.view)
			.presentationDestination(\.$destination, action: /Action.child .. Action.ChildAction.destination) {
				Destinations()
			}
	}

	func core(state: inout State, action: Action.ViewAction) -> EffectTask<Action> {
		switch action {
		case .appeared:
			return .run { [address = state.address] send in
				await send(.delegate(.refresh(address)))
			}
		case .dismissAccountDetailsButtonTapped:
			return .run { send in
				await send(.delegate(.dismissAccountDetails))
			}
		case .displayAccountPreferencesButtonTapped:
			return .run { [address = state.address] send in
				await send(.delegate(.displayAccountPreferences(address)))
			}
		case .copyAddressButtonTapped:
			let address = state.address.address
			return .fireAndForget { pasteboardClient.copyString(address) }
		case .pullToRefreshStarted:
			return .run { [address = state.address] send in
				await send(.delegate(.refresh(address)))
			}
		case .transferButtonTapped:
			state.destination = .transfer(AssetTransfer.State(from: state.account))
			return .none
		}
	}
}

// MARK: - CaseReduce
// Goes in e.g. Prelude

public struct CaseReduce<State, Action>: ReducerProtocol {
	@usableFromInline
	let reduce: (inout State, Action) -> EffectTask<Action>

	@usableFromInline
	init<CaseAction>(
		_ reduce: @escaping (inout State, CaseAction) -> EffectTask<Action>,
		case casePath: CasePath<Action, CaseAction>
	) {
		self.reduce = { state, action in
			guard let inputAction = casePath.extract(from: action) else { return .none }
			return reduce(&state, inputAction)
		}
	}

	@inlinable
	public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		self.reduce(&state, action)
	}
}
