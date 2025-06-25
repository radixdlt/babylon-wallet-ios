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
	@Dependency(\.dAppsDirectoryClient) var dAppsDirectoryClient

	typealias Store = StoreOf<Self>

	// MARK: State

	// TODO: Add `@ObservableState` after migrating `DappDetails` to `ObservableState`
	struct State: Sendable, Hashable {
		var filtering: DAppsFiltering.State = .init()
		var dappsWithClaims: Set<DappDefinitionAddress> = []

		var categorizedDApps: Loadable<DAppsDirectory.DAppsCategories> = .idle

		var displayedDapps: Loadable<DAppsDirectory.DAppsCategories> {
			categorizedDApps.filtered(filtering.searchTerm, filtering.filterTags)
		}

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
		case loadedDapps(TaskResult<DAppsDirectory.DApps>)
		case setDappsWithClaims([DappDefinitionAddress])
	}

	@CasePathable
	enum ChildAction: Sendable, Equatable {
		case filtering(DAppsFiltering.Action)
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
		Scope(state: \.filtering, action: \.child.filtering) {
			DAppsFiltering()
		}

		Reduce(core)
			.ifLet(destinationPath, action: \.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			return loadAuthorizedDapps(&state)
				.merge(with: accountLockerClaimsEffect())

		case let .didSelectDapp(dAppID):
			state.destination = .presentedDapp(.init(dAppDefinitionAddress: dAppID, context: .settings(.dAppsList)))
			return .none
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .loadedDapps(.success(dApps)):
			let grouped = dApps.grouped(by: \.category)
				.map { category, dApps in
					DAppsDirectory.DAppsCategory(category: category, dApps: dApps.asIdentified())
				}
				.sorted(by: \.category)
				.asIdentified()

			state.filtering.allTags = OrderedSet(dApps.flatMap(\.tags).sorted())
			state.categorizedDApps = .success(grouped)
			return .none

		case let .loadedDapps(.failure(error)):
			errorQueue.schedule(error)
			return .none

		case let .setDappsWithClaims(dappsWithClaims):
			state.dappsWithClaims = Set(dappsWithClaims)
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
			.concatenate(with: loadAuthorizedDapps(&state))

		default:
			.none
		}
	}

	private func loadAuthorizedDapps(_ state: inout State) -> Effect<Action> {
		state.categorizedDApps.refresh(from: .loading)
		return .run { send in
			let result = await TaskResult {
				let authorizedDapps = try await authorizedDappsClient.getAuthorizedDapps()
				let dAppsList = await (try? dAppsDirectoryClient.fetchDApps(false)) ?? []
				let dAppDetails = await (try? onLedgerEntitiesClient
					.getAssociatedDapps(
						authorizedDapps.map(\.dappDefinitionAddress),
						cachingStrategy: .useCache
					)
					.asIdentified()) ?? []

				let dApps = authorizedDapps.map { profileDApp in
					let dAppTagsCategory = dAppsList[id: profileDApp.id]
					let details = dAppDetails[id: profileDApp.id]

					return DAppsDirectory.DApp(
						dAppDefinitionAddress: profileDApp.dAppDefinitionAddress,
						dAppDetails: details,
						dAppDirectoryDetails: dAppTagsCategory,
						approvedDappName: profileDApp.displayName
					)
				}
				.asIdentified()

				return dApps
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
