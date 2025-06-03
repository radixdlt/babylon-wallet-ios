import ComposableArchitecture
import Sargon
import SwiftUI

// MARK: - AuthorizedDapps
@Reducer
struct AuthorizedDappsFeature: Sendable, FeatureReducer {
	@Dependency(\.authorizedDappsClient) var authorizedDappsClient
	@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient
	@Dependency(\.accountLockersClient) var accountLockersClient
	@Dependency(\.errorQueue) var errorQueue

	typealias Store = StoreOf<Self>

	// MARK: State

	// TODO: Add `@ObservableState` after migrating `DappDetails` to `ObservableState`
	struct State: Sendable, Hashable {
		var dApps: AuthorizedDapps = []
		var thumbnails: [AuthorizedDapp.ID: URL] = [:]
		var dappsWithClaims: [DappDefinitionAddress] = []

		@PresentationState
		var destination: Destination.State? = nil

		init(destination: Destination.State? = nil) {
			self.destination = destination
		}
	}

	typealias Action = FeatureAction<Self>

	// MARK: Action

	@CasePathable
	enum ViewAction: Sendable, Equatable {
		case task
		case didSelectDapp(AuthorizedDapp.ID)
	}

	enum InternalAction: Sendable, Equatable {
		case loadedDapps(TaskResult<AuthorizedDapps>)
		case loadedThumbnail(URL, dApp: AuthorizedDapp.ID)
		case presentDappDetails(DappDetails.State)
		case failedToGetDetailsOfDapp(id: AuthorizedDapp.ID)
		case setDappsWithClaims([DappDefinitionAddress])
	}

	// MARK: Destination

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Hashable, Sendable {
			case presentedDapp(DappDetails.State)
		}

		@CasePathable
		enum Action: Equatable, Sendable {
			case presentedDapp(DappDetails.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.presentedDapp, action: \.presentedDapp) {
				DappDetails()
			}
		}
	}

	// MARK: Reducer

	init() {}

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: \.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			loadAuthorizedDapps()
				.merge(with: accountLockerClaimsEffect())

		case let .didSelectDapp(dAppID):
			.run { send in
				let dApp = try await authorizedDappsClient.getDetailedDapp(dAppID)
				let presentedDappState = DappDetails.State(dApp: dApp, context: .dAppsList)
				await send(.internal(.presentDappDetails(presentedDappState)))
			} catch: { error, send in
				errorQueue.schedule(error)
				await send(.internal(.failedToGetDetailsOfDapp(id: dAppID)))
			}
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
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

		case let .setDappsWithClaims(dappsWithClaims):
			state.dappsWithClaims = dappsWithClaims
			return .none
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
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

	private func accountLockerClaimsEffect() -> Effect<Action> {
		.run { send in
			for try await dappsWithClaims in await accountLockersClient.dappsWithClaims() {
				guard !Task.isCancelled else { return }
				await send(.internal(.setDappsWithClaims(dappsWithClaims)))
			}
		}
	}
}
