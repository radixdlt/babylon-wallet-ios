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
		case pullToRefreshStarted
	}

	enum InternalAction: Sendable, Equatable {
		case loadedDApps(TaskResult<State.DApps>)
	}

	@CasePathable
	enum ChildAction: Sendable, Equatable {
		case dAppsList(DAppsList.Action)
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
		Reduce(core)
			.ifLet(destinationPath, action: \.destination) {
				Destination()
			}
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			return .run { send in
				let dAppList = try await dAppsDirectoryClient.fetchDApps()
				let dAppDetails = try await onLedgerEntitiesClient
					.getAssociatedDapps(dAppList.map(\.dAppDefinitionAddress))
					.asIdentified()

				let dApps = dAppList.map { dApp in
					let details = dAppDetails[id: dApp.id]
					return State.DApp(
						dAppDefinitionAddress: dApp.dAppDefinitionAddress,
						name: details?.metadata.name ?? "Unknown dApp",
						thumbnail: details?.metadata.iconURL,
						description: details?.metadata.description,
						tags: dApp.tags
					)
				}
				.asIdentified()

				await send(.internal(.loadedDApps(.success(dApps))))
			} catch: { error, send in
				errorQueue.schedule(error)
				await send(.internal(.loadedDApps(.failure(error))))
			}

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
			return .none

		case .pullToRefreshStarted:
			return .none
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .loadedDApps(.success(dApps)):
			state.dApps = .success(dApps)
			return .none
		case let .loadedDApps(.failure(error)):
			state.dApps = .failure(error)
			return .none
		}
	}
}

extension DAppsDirectory.State {
	var displayedDApps: Loadable<DApps> {
		dApps.filter { dApp in
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
