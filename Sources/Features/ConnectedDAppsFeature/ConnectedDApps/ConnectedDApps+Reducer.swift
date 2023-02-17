import FeaturePrelude
import ProfileClient

// MARK: - ConnectedDApps
public struct ConnectedDApps: Sendable, FeatureReducer {
	@Dependency(\.profileClient) var profileClient

	public typealias Store = StoreOf<Self>

	// MARK: State

	public struct State: Sendable, Hashable {
		public var dApps: IdentifiedArrayOf<OnNetwork.ConnectedDapp>

		@PresentationState
		public var presentedDApp: DAppProfile.State?

		public init(dApps: IdentifiedArrayOf<OnNetwork.ConnectedDapp> = [], presentedDApp: DAppProfile.State? = nil) {
			self.dApps = dApps
			self.presentedDApp = presentedDApp
		}
	}

	// MARK: Action

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case didSelectDApp(OnNetwork.ConnectedDapp.ID)
	}

	public enum InternalAction: Sendable, Equatable {
		case loadedDApps(IdentifiedArrayOf<OnNetwork.ConnectedDapp>)
		case forgotDApp(OnNetwork.ConnectedDapp.ID)
	}

	public enum DelegateAction: Sendable, Equatable {}

	public enum ChildAction: Sendable, Equatable {
		case presentedtedDApp(PresentationActionOf<DAppProfile>)
	}

	// MARK: Reducer

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.presentationDestination(\.$presentedDApp, action: /Action.child .. ChildAction.presentedtedDApp) {
				DAppProfile()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .task {
				let dApps = try await profileClient.getConnectedDapps() // TODO: • Handle error?
				return .internal(.loadedDApps(dApps))
			}
		case let .didSelectDApp(id):
			guard let dApp = state.dApps[id: id] else { return .none } // TODO: • Handle error? Put details directly in enum case?

			return .task {
				let detailed = try await profileClient.detailsForConnectedDapp(dApp)
				let presented = DAppProfile.State(dApp: detailed)
				return .child(.presentedtedDApp(.present(presented)))
			}
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .presentedtedDApp(.presented(.delegate(.forgetDApp(id: dAppID, networkID: networkID)))):
			let presentedDAppID = state.presentedDApp?.dApp.dAppDefinitionAddress
			return .run { send in
				try await profileClient.forgetConnectedDApp(dAppID, networkID)
				if dAppID == presentedDAppID {
					await send(.child(.presentedtedDApp(.dismiss)), animation: .default)
				}

				await send(.internal(.forgotDApp(dAppID)))
			}

		case .presentedtedDApp:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .loadedDApps(dApps):
			state.dApps = dApps
			return .none

		case let .forgotDApp(dAppID):
			// Could pop up a message here
			return .none
		}
	}
}
