// MARK: - AllDapps
extension DAppsDirectory {
	@Reducer
	struct AllDapps: Sendable, FeatureReducer {
		@ObservableState
		struct State: Sendable, Hashable {
			var filtering: DAppsFiltering.State = .init()
			var dApps: Loadable<IdentifiedArrayOf<DAppsCategory>> = .idle

			var displayedDApps: Loadable<DAppsDirectory.DAppsCategories> {
				dApps.filtered(filtering.searchTerm, filtering.filterTags)
			}

			@Presents
			var destination: Destination.State? = nil
		}

		typealias Action = FeatureAction<Self>

		@CasePathable
		enum ViewAction: Sendable, Equatable {
			case task
			case didSelectDapp(DApp.ID)
			case pullToRefreshStarted
		}

		@CasePathable
		enum InternalAction: Sendable, Equatable {
			case loadedDApps(TaskResult<DApps>)
		}

		@CasePathable
		enum ChildAction: Sendable, Equatable {
			case filtering(DAppsFiltering.Action)
		}

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

		@Dependency(\.dAppsDirectoryClient) var dAppsDirectoryClient
		@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient
		@Dependency(\.errorQueue) var errorQueue

		private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

		var body: some ReducerOf<Self> {
			Scope(state: \.filtering, action: \.child.filtering) {
				DAppsFiltering()
			}

			Reduce(core)
				.ifLet(destinationPath, action: \.destination) {
					Destination()
				}
		}

		func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
			switch viewAction {
			case .task:
				guard !state.dApps.isSuccess else {
					return .none
				}
				state.dApps = .loading
				return loadDapps()

			case let .didSelectDapp(id):
				state.destination = .presentedDapp(.init(dAppDefinitionAddress: id))
				return .none

			case .pullToRefreshStarted:
				guard !state.dApps.isLoading else {
					return .none
				}

				if case .failure = state.dApps {
					state.dApps = .loading
				}

				return loadDapps(forceRefresh: true)
			}
		}

		func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
			switch internalAction {
			case let .loadedDApps(.success(dApps)):
				let grouped = dApps.grouped(by: \.category)
					.map { category, dApps in
						DAppsCategory(category: category, dApps: dApps.asIdentified())
					}
					.sorted(by: \.category)
					.asIdentified()

				state.dApps = .success(grouped)
				return .none
			case let .loadedDApps(.failure(error)):
				errorQueue.schedule(error)
				guard !state.dApps.isSuccess else {
					return .none
				}
				state.dApps = .failure(error)
				return .none
			}
		}

		func loadDapps(forceRefresh: Bool = false) -> Effect<Action> {
			.run { send in
				let result = await TaskResult {
					let dAppList = try await dAppsDirectoryClient.fetchDApps(forceRefresh)
					let dAppDetails = try await onLedgerEntitiesClient
						.getAssociatedDapps(
							dAppList.map(\.address),
							cachingStrategy: forceRefresh ? .forceUpdate : .useCache
						)
						.asIdentified()

					return dAppList.map { dApp in
						let details = dAppDetails[id: dApp.id]
						return DApp(
							dAppDefinitionAddress: dApp.address,
							name: details?.metadata.name ?? dApp.name,
							thumbnail: details?.metadata.iconURL,
							description: details?.metadata.description,
							tags: dApp.tags,
							category: dApp.dAppCategory
						)
					}
					.asIdentified()
				}

				await send(.internal(.loadedDApps(result)))
			}
		}
	}
}
