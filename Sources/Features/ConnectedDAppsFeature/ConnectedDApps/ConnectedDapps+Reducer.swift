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
		public var presentedDapp: DappDetails.State?

		public init(dApps: IdentifiedArrayOf<OnNetwork.ConnectedDapp> = [], presentedDapp: DappDetails.State? = nil) {
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
	}

	public enum ChildAction: Sendable, Equatable {
		case presentedDapp(PresentationActionOf<DappDetails>)
	}

	// MARK: Reducer

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.presentationDestination(\.$presentedDapp, action: /Action.child .. ChildAction.presentedDapp) {
				DappDetails()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .task {
				let dApps = try await profileClient.getConnectedDapps() // TODO: • Handle error?
				return .internal(.loadedDapps(dApps))
			}
		case let .didSelectDapp(dAppID):
			return .task {
				let details = try await profileClient.getDetailedDapp(dAppID)
				let detailsState = DappDetails.State(dApp: details)
				return .child(.presentedDapp(.present(detailsState)))
			}
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .presentedDapp(.presented(.delegate(.dAppForgotten))):

			// Could pop up a message here
			// Does not work
			return .send(.child(.presentedDapp(.dismiss)))

//			// This does not work either
//			state.presentedDapp = nil
//			return .none

		case .presentedDapp:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .loadedDapps(dApps):
			state.dApps = dApps
			return .none
		}
	}
}
