import FeaturePrelude
import ProfileClient

// MARK: - AuthorizedDapps
public struct AuthorizedDapps: Sendable, FeatureReducer {
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.profileClient) var profileClient

	public typealias Store = StoreOf<Self>

	// MARK: State

	public struct State: Sendable, Hashable {
		public var dApps: OnNetwork.AuthorizedDapps

		@PresentationState
		public var presentedDapp: DappDetails.State?

		public init(
			dApps: OnNetwork.AuthorizedDapps = [],
			presentedDapp: DappDetails.State? = nil
		) {
			self.dApps = dApps
			self.presentedDapp = presentedDapp
		}
	}

	// MARK: Action

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case didSelectDapp(OnNetwork.AuthorizedDapp.ID)
	}

	public enum InternalAction: Sendable, Equatable {
		case loadedDapps(TaskResult<OnNetwork.AuthorizedDapps>)
		case presentDappDetails(DappDetails.State)
	}

	public enum ChildAction: Sendable, Equatable {
		case presentedDapp(PresentationAction<DappDetails.Action>)
	}

	// MARK: Reducer

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$presentedDapp, action: /Action.child .. ChildAction.presentedDapp) {
				DappDetails()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .task {
				await loadAuthorizedDapps()
			}

		case let .didSelectDapp(dAppID):
			return .run { send in
				let details = try await profileClient.getDetailedDapp(dAppID)
				let presentedDappState = DappDetails.State(dApp: details)
				await send(.internal(.presentDappDetails(presentedDappState)))
			} catch: { error, _ in
				errorQueue.schedule(error)
			}
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .loadedDapps(.success(dApps)):
			state.dApps = dApps
			return .none
		case let .loadedDapps(.failure(error)):
			errorQueue.schedule(error)
			return .none
		case let .presentDappDetails(presentedDappState):
			state.presentedDapp = presentedDappState
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .presentedDapp(.presented(.delegate(.dAppForgotten))):
			return .run { send in
				await send(.child(.presentedDapp(.dismiss)))
				await send(loadAuthorizedDapps())
			}

		case .presentedDapp:
			return .none
		}
	}

	private func loadAuthorizedDapps() async -> Action {
		let result = await TaskResult {
			try await profileClient.getAuthorizedDapps()
		}
		return .internal(.loadedDapps(result))
	}
}
