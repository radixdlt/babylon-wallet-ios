import FeaturePrelude
import ProfileClient

// MARK: - ConnectedDapps
public struct ConnectedDapps: Sendable, FeatureReducer {
	@Dependency(\.profileClient) var profileClient

	public typealias Store = StoreOf<Self>

	// MARK: State

	public struct State: Sendable, Hashable {
		public var dApps: IdentifiedArrayOf<OnNetwork.ConnectedDapp>

		@PresentationState
		public var presentedDapp: DappProfile.State?

		public init(dApps: IdentifiedArrayOf<OnNetwork.ConnectedDapp> = [], presentedDapp: DappProfile.State? = nil) {
			self.dApps = dApps
			self.presentedDapp = presentedDapp
		}
	}

	// MARK: Action

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case didSelectDapp(OnNetwork.ConnectedDapp.ID)
	}

	public enum InternalAction: Sendable, Equatable {
		case loadedDapps(IdentifiedArrayOf<OnNetwork.ConnectedDapp>)
		case forgotDapp(OnNetwork.ConnectedDapp.ID)
	}

	public enum DelegateAction: Sendable, Equatable {}

	public enum ChildAction: Sendable, Equatable {
		case presentedtedDapp(PresentationActionOf<DappProfile>)
	}

	// MARK: Reducer

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.presentationDestination(\.$presentedDapp, action: /Action.child .. ChildAction.presentedtedDapp) {
				DappProfile()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .task {
				let dApps = try await profileClient.getConnectedDapps() // TODO: • Handle error?
				return .internal(.loadedDapps(dApps))
			}
		case let .didSelectDapp(id):
			guard let dApp = state.dApps[id: id] else { return .none } // TODO: • Handle error? Put details directly in enum case?

			return .task {
				let detailed = try await profileClient.detailsForConnectedDapp(dApp)
				let presented = DappProfile.State(dApp: detailed)
				return .child(.presentedtedDapp(.present(presented)))
			}
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .presentedtedDapp(.presented(.delegate(.forgetDapp(id: dAppID, networkID: networkID)))):
			let presentedDappID = state.presentedDapp?.dApp.dAppDefinitionAddress
			return .run { send in
				try await profileClient.forgetConnectedDapp(dAppID, networkID)
				if dAppID == presentedDappID {
					await send(.child(.presentedtedDapp(.dismiss)), animation: .default)
				}

				await send(.internal(.forgotDapp(dAppID)))
			}

		case .presentedtedDapp:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .loadedDapps(dApps):
			state.dApps = dApps
			return .none

		case let .forgotDapp(dAppID):
			// Could pop up a message here
			return .none
		}
	}
}
