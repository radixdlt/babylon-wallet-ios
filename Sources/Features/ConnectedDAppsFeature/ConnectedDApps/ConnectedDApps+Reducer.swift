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
		public var selectedDApp: DAppProfile.State?

		public init(dApps: IdentifiedArrayOf<OnNetwork.ConnectedDapp> = [], selectedDApp: DAppProfile.State? = nil) {
			self.dApps = dApps
			self.selectedDApp = selectedDApp
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
		case selectedDApp(PresentationActionOf<DAppProfile>)
	}

	// MARK: Reducer

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.presentationDestination(\.$selectedDApp, action: /Action.child .. ChildAction.selectedDApp) {
				DAppProfile()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .task {
				let dApps = try await profileClient.getConnectedDapps() // TODO: • Handle error?

				print("APPEARED")
				for dApp in dApps {
					print("    \(dApp.displayName.rawValue)")
					print("    \(dApp.dAppDefinitionAddress.address)")
					print("    \(dApp.networkID)")
					print("    #\(dApp.referencesToAuthorizedPersonas.count)")
				}
				return .internal(.loadedDApps(dApps))
			}
		case let .didSelectDApp(id):
			guard let dApp = state.dApps[id: id] else { return .none } // TODO: • Handle error? Put details directly in enum case?

			return .task {
				let detailed = try await profileClient.detailsForConnectedDapp(dApp)
				let presented = DAppProfile.State(dApp: detailed)
				return .child(.selectedDApp(.present(presented)))
			}
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .selectedDApp(.presented(.delegate(.forgetDApp(id: dAppID, networkID: networkID)))):

			return .task {
				print("REDUCER child forgetDApp")
				try await profileClient.forgetConnectedDApp(dAppID, networkID)
				print("REDUCER child forgetDApp OK")
				return .internal(.forgotDApp(dAppID))
			}

		case .selectedDApp:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .loadedDApps(dApps):
			state.dApps = dApps
			return .none

		case let .forgotDApp(dAppID):
			print("REDUCER internal forgotDApp, dismissing")
			if state.selectedDApp?.dApp.dAppDefinitionAddress == dAppID {
				state.selectedDApp = nil
			}

			return .none
		}
	}
}
