import ComposableArchitecture
import Sargon
import SwiftUI

// MARK: - AuthorizedDapps
public struct AuthorizedDappsFeature: Sendable, FeatureReducer {
	@Dependency(\.authorizedDappsClient) var authorizedDappsClient
	@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient
	@Dependency(\.errorQueue) var errorQueue

	public typealias Store = StoreOf<Self>

	// MARK: State

	public struct State: Sendable, Hashable {
		public var dApps: IdentifiedArrayOf<AuthorizedDapp> = []
		public var thumbnails: [AuthorizedDapp.ID: URL] = [:]

		@PresentationState
		public var destination: Destination.State? = nil

		public init(destination: Destination.State? = nil) {
			self.destination = destination
		}
	}

	// MARK: Action

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case didSelectDapp(AuthorizedDapp.ID)
	}

	public enum InternalAction: Sendable, Equatable {
		case loadedDapps(TaskResult<IdentifiedArrayOf<AuthorizedDapp>>)
		case loadedThumbnail(URL, dApp: AuthorizedDapp.ID)
		case presentDappDetails(DappDetails.State)
		case failedToGetDetailsOfDapp(id: AuthorizedDapp.ID)
	}

	// MARK: Destination

	public struct Destination: DestinationReducer {
		public enum State: Hashable, Sendable {
			case presentedDapp(DappDetails.State)
		}

		public enum Action: Equatable, Sendable {
			case presentedDapp(DappDetails.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.presentedDapp, action: /Action.presentedDapp) {
				DappDetails()
			}
		}
	}

	// MARK: Reducer

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			loadAuthorizedDapps()

		case let .didSelectDapp(dAppID):
			.run { send in
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
				try await onLedgerEntitiesClient.getAssociatedDapps(dApps.map(\.id)).asyncForEach { dApp in
					if let iconURL = dApp.metadata.iconURL {
						await send(.internal(.loadedThumbnail(iconURL, dApp: dApp.address)))
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
			state.destination = .presentedDapp(presentedDappState)
			return .none
		case let .loadedThumbnail(thumbnail, dApp: id):
			state.thumbnails[id] = thumbnail
			return .none
		}
	}

	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .presentedDapp(.delegate(.dAppForgotten)):
			.run { send in
				// TODO: Couldn't this simply be: state.destination = nil
				await send(.destination(.dismiss))
			}
			.concatenate(with: loadAuthorizedDapps())

		default:
			.none
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
