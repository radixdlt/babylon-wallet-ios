// MARK: - DAppsDirectory
@Reducer
struct DAppsDirectory: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		typealias DApps = IdentifiedArrayOf<DApp>
		struct DApp: Sendable, Hashable, Identifiable {
			var id: DappDefinitionAddress {
				dAppDefinitionAddress
			}

			let dAppDefinitionAddress: DappDefinitionAddress
			let name: String
			let thumbnail: URL?
			let description: String?
			let tags: IdentifiedArrayOf<DAppsDirectoryClient.DApp.Tag>
		}

		var searchBarFocused: Bool = false
		var dApps: Loadable<DApps> = .idle
		var searchTerm: String = ""
		var filterTags: OrderedSet<DAppsDirectoryClient.DApp.Tag> = []

		@Presents
		var destination: Destination.State? = nil
	}

	typealias Action = FeatureAction<Self>

	@CasePathable
	enum ViewAction: Sendable, Equatable {
		case task
		case searchTermChanged(String)
		case didSelectDapp(State.DApp.ID)
		case focusChanged(Bool)
		case filtersTapped
		case filterRemoved(DAppsDirectoryClient.DApp.Tag)
		case pullToRefreshStarted
	}

	@CasePathable
	enum InternalAction: Sendable, Equatable {
		case loadedDApps(TaskResult<State.DApps>)
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Hashable, Sendable {
			case presentedDapp(DappDetails.State)
			case tagSelection(DAppTagsSelection.State)
		}

		@CasePathable
		enum Action: Equatable, Sendable {
			case presentedDapp(DappDetails.Action)
			case tagSelection(DAppTagsSelection.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.presentedDapp, action: \.presentedDapp) {
				DappDetails()
			}

			Scope(state: \.tagSelection, action: \.tagSelection) {
				DAppTagsSelection()
			}
		}
	}

	@Dependency(\.dAppsDirectoryClient) var dAppsDirectoryClient
	@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient
	@Dependency(\.errorQueue) var errorQueue

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	var body: some ReducerOf<Self> {
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

		case let .searchTermChanged(searchTerm):
			state.searchTerm = searchTerm.trimmingWhitespacesAndNewlines()
			return .none

		case let .focusChanged(isFocused):
			state.searchBarFocused = isFocused
			return .none

		case .filtersTapped:
			state.destination = .tagSelection(.init(selectedTags: state.filterTags))
			return .none

		case let .filterRemoved(tag):
			state.filterTags.remove(tag)
			return .none

		case .pullToRefreshStarted:
			guard !state.dApps.isLoading else {
				return .none
			}

			if case .failure = state.dApps {
				state.dApps = .loading
			}

			return loadDapps()
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .loadedDApps(.success(dApps)):
			state.dApps = .success(dApps)
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

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case let .tagSelection(.delegate(.selectedTags(tags))):
			state.filterTags = tags
			return .none
		default:
			return .none
		}
	}

	func loadDapps() -> Effect<Action> {
		.run { send in
			let result = await TaskResult {
				let dAppList = try await dAppsDirectoryClient.fetchDApps()
				let dAppDetails = try await onLedgerEntitiesClient
					.getAssociatedDapps(dAppList.map(\.address))
					.asIdentified()

				return dAppList.map { dApp in
					let details = dAppDetails[id: dApp.id]
					return State.DApp(
						dAppDefinitionAddress: dApp.address,
						name: details?.metadata.name ?? dApp.name,
						thumbnail: details?.metadata.iconURL,
						description: details?.metadata.description,
						tags: dApp.tags
					)
				}
				.asIdentified()
			}

			await send(.internal(.loadedDApps(result)))
		}
	}
}

extension DAppsDirectory.State {
	var displayedDApps: Loadable<DApps> {
		dApps
			.filter { dApp in
				guard !filterTags.isEmpty else {
					return true
				}

				return dApp.tags.contains { filterTags.contains($0) }
			}
			.filter { dApp in
				if !searchTerm.isEmpty {
					dApp.name.range(of: searchTerm, options: .caseInsensitive) != nil ||
						dApp.description?.range(of: searchTerm, options: .caseInsensitive) != nil
				} else {
					true
				}
			}

			.map { $0.asIdentified() }
	}
}

extension OrderedSet<DAppsDirectoryClient.DApp.Tag> {
	var asFilterItems: IdentifiedArrayOf<ItemFilter<DAppsDirectoryClient.DApp.Tag>> {
		self.elements.map {
			$0.asItemFilter(isActive: true)
		}.asIdentified()
	}
}
