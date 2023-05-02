import AuthorizedDappsClient
import FeaturePrelude
import GatewayAPI

// MARK: - AuthorizedDapps
public struct AuthorizedDapps: Sendable, FeatureReducer {
	@Dependency(\.authorizedDappsClient) var authorizedDappsClient
	@Dependency(\.cacheClient) var cacheClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.gatewayAPIClient) var gatewayAPIClient

	public typealias Store = StoreOf<Self>

	// MARK: State

	public struct State: Sendable, Hashable {
		public var dApps: Profile.Network.AuthorizedDapps
		public var thumbnails: [Profile.Network.AuthorizedDapp.ID: URL] = [:]

		@PresentationState
		public var presentedDapp: DappDetails.State?

		public init(
			dApps: Profile.Network.AuthorizedDapps = [],
			presentedDapp: DappDetails.State? = nil
		) {
			self.dApps = dApps
			self.presentedDapp = presentedDapp
		}
	}

	// MARK: Action

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case didSelectDapp(Profile.Network.AuthorizedDapp.ID)
	}

	public enum InternalAction: Sendable, Equatable {
		case loadedDapps(TaskResult<Profile.Network.AuthorizedDapps>)
		case loadedThumbnail(URL, dApp: Profile.Network.AuthorizedDapp.ID)
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
				let details = try await authorizedDappsClient.getDetailedDapp(dAppID)
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
			return .run { send in
				for dApp in dApps {
					let iconURL = try? await cacheClient.withCaching(
						cacheEntry: .dAppMetadata(dApp.id.address),
						request: { try await gatewayAPIClient.getEntityMetadata(dApp.id.address) }
					).iconURL
					if let iconURL {
						await send(.internal(.loadedThumbnail(iconURL, dApp: dApp.id)))
					}
				}
			}
		case let .loadedDapps(.failure(error)):
			errorQueue.schedule(error)
			return .none
		case let .presentDappDetails(presentedDappState):
			state.presentedDapp = presentedDappState
			return .none
		case let .loadedThumbnail(thumbnail, dApp: id):
			state.thumbnails[id] = thumbnail
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
			try await authorizedDappsClient.getAuthorizedDapps()
		}
		return .internal(.loadedDapps(result))
	}
}
