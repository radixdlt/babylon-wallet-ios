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
		public var dApps: Profile.Network.AuthorizedDapps = []
		public var thumbnails: [Profile.Network.AuthorizedDapp.ID: URL] = [:]

		@PresentationState
		public var presentedDapp: DappDetails.State?

		public init(presentedDapp: DappDetails.State? = nil) {
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
		case failedToGetDetailsOfDapp(id: Profile.Network.AuthorizedDapp.ID)
	}

	public enum ChildAction: Sendable, Equatable {
		case presentedDapp(PresentationAction<DappDetails.Action>)
	}

	// MARK: Reducer

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(\.$presentedDapp, action: /Action.child .. ChildAction.presentedDapp) {
				DappDetails()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			return loadAuthorizedDapps()

		case let .didSelectDapp(dAppID):
			return .run { send in
				let dApp = try await authorizedDappsClient.getDetailedDapp(dAppID)
				let presentedDappState = DappDetails.State(dApp: dApp, context: .authorizedDapps)
				await send(.internal(.presentDappDetails(presentedDappState)))
			} catch: { error, send in
				errorQueue.schedule(error)
				await send(.internal(.failedToGetDetailsOfDapp(id: dAppID)))
			}
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .loadedDapps(.success(dApps)):
			state.dApps = dApps
			return .run { send in
				for dApp in dApps {
					let iconURL = try? await cacheClient.withCaching(
						cacheEntry: .dAppMetadata(dApp.id.address),
						request: { try await gatewayAPIClient.getEntityMetadata(dApp.id.address, [.iconURL]) }
					).iconURL
					if let iconURL {
						await send(.internal(.loadedThumbnail(iconURL, dApp: dApp.id)))
					}
				}
			}

		case let .failedToGetDetailsOfDapp(dappId):
			#if DEBUG
			return .run { _ in
				loggerGlobal.notice("DEBUG ONLY deleting authorized dapp since we failed to load detailed info about it")
				try? await authorizedDappsClient.forgetAuthorizedDapp(dappId, nil)

			}.concatenate(with: loadAuthorizedDapps())
			#else
			// FIXME: Should we have to handle this, this is a discrepancy bug..
			return .none
			#endif

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

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .presentedDapp(.presented(.delegate(.dAppForgotten))):
			return .run { send in
				await send(.child(.presentedDapp(.dismiss)))
			}.concatenate(with: loadAuthorizedDapps())

		case .presentedDapp:
			return .none
		}
	}

	private func loadAuthorizedDapps() -> Effect<Action> {
		.run { send in
			let result = await TaskResult {
				try await authorizedDappsClient.getAuthorizedDapps()
			}
			await send(.internal(.loadedDapps(result)))
		}
	}
}
