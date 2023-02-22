import FeaturePrelude
import ProfileClient

// MARK: - ConnectedDapps
public struct ConnectedDapps: Sendable, FeatureReducer {
	@Dependency(\.errorQueue) var errorQueue
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
		case loadedDapps(TaskResult<IdentifiedArrayOf<OnNetwork.ConnectedDapp>>)
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
				await loadConnectedDapps()

				// Option B:
//				let result = await TaskResult {
//					try await profileClient.getConnectedDapps()
//				}
//				return .internal(.loadedDapps(result))
			}

		case let .didSelectDapp(dAppID):
			return .run { send in
				let details = try await profileClient.getDetailedDapp(dAppID)
				let presentedState = DappDetails.State(dApp: details)
				await send(.child(.presentedDapp(.present(presentedState))))
			} catch: { error, _ in
				errorQueue.schedule(error)
			}
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .presentedDapp(.presented(.delegate(.dAppForgotten))):
			return .run { send in
				let action = await loadConnectedDapps()
				if case .internal(.loadedDapps(.success)) = action {
					await send(.child(.presentedDapp(.dismiss)))
				}
				await send(action)
			}

// Option B:
//			return .run { send in
//				let dApps = try await profileClient.getConnectedDapps()
//				await send(.internal(.loadedDapps(.success(dApps))))
//				await send(.child(.presentedDapp(.dismiss)))
//			} catch: { error, _ in
//				errorQueue.schedule(error)
//			}

		case .presentedDapp:
			return .none
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
		}
	}

	private func loadConnectedDapps() async -> Action {
		let result = await TaskResult {
			try await profileClient.getConnectedDapps()
		}
		return .internal(.loadedDapps(result))
	}
}
