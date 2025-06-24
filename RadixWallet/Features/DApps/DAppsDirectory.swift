// MARK: - DAppsDirectory
@Reducer
struct DAppsDirectory: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		var filtering: DAppsFiltering.State = .init()
		var dApps: Loadable<IdentifiedArrayOf<DAppsCategory>> = .idle

		@Presents
		var destination: Destination.State? = nil
	}

	typealias Action = FeatureAction<Self>

	@CasePathable
	enum ViewAction: Sendable, Equatable {
		case task
		case didSelectDapp(State.DApp.ID)
		case pullToRefreshStarted
	}

	@CasePathable
	enum InternalAction: Sendable, Equatable {
		case loadedDApps(TaskResult<State.DApps>)
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
					State.DAppsCategory(category: category, dApps: dApps.asIdentified())
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
					return State.DApp(
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

extension DAppsDirectory.State {
	var displayedDApps: Loadable<IdentifiedArrayOf<DAppsCategory>> {
		dApps.compactMapValue {
			let filteredDapps = $0.dApps.filter { dApp in
				guard !filtering.filterTags.isEmpty else {
					return true
				}

				return dApp.tags.contains { filtering.filterTags.contains($0) }
			}
			.filter { dApp in
				if !filtering.searchTerm.isEmpty {
					dApp.name.range(of: filtering.searchTerm, options: .caseInsensitive) != nil ||
						dApp.description?.range(of: filtering.searchTerm, options: .caseInsensitive) != nil
				} else {
					true
				}
			}
			.asIdentified()

			guard !filteredDapps.isEmpty else {
				return nil
			}

			return DAppsCategory(category: $0.category, dApps: filteredDapps)
		}
		.map { $0.sorted(by: \.category).asIdentified() }
	}

	typealias DApps = IdentifiedArrayOf<DApp>
	typealias DAppsCategories = IdentifiedArrayOf<DAppsCategory>
	struct DApp: Sendable, Hashable, Identifiable {
		var id: DappDefinitionAddress {
			dAppDefinitionAddress
		}

		let dAppDefinitionAddress: DappDefinitionAddress
		let name: String
		let thumbnail: URL?
		let description: String?
		let tags: IdentifiedArrayOf<DAppsDirectoryClient.DApp.Tag>
		let category: DAppsDirectoryClient.DApp.Category
	}

	struct DAppsCategory: Identifiable, Equatable, Hashable {
		var id: DAppsDirectoryClient.DApp.Category {
			category
		}

		let category: DAppsDirectoryClient.DApp.Category
		let dApps: DApps
	}
}

extension OrderedSet<DAppsDirectoryClient.DApp.Tag> {
	var asFilterItems: IdentifiedArrayOf<ItemFilter<DAppsDirectoryClient.DApp.Tag>> {
		self.elements.map {
			$0.asItemFilter(isActive: true)
		}.asIdentified()
	}
}
