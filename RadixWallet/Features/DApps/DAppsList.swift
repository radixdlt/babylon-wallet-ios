// MARK: - DAppsList
@Reducer
struct DAppsList: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		struct DApp: Sendable, Hashable, Identifiable {
			var id: DappDefinitionAddress {
				dAppDefinitionAddress
			}

			let dAppDefinitionAddress: DappDefinitionAddress
			let name: String
			let thumbnail: URL?
			let description: String?
			let hasClaim: Bool
		}

		let dAppsList: IdentifiedArrayOf<DappDefinitionAddress>
		var dAppDetails: Loadable<IdentifiedArrayOf<DApp>> = .idle
		@Presents
		var destination: Destination.State? = nil

		init(
			dAppsList: IdentifiedArrayOf<DappDefinitionAddress>
		) {
			self.dAppsList = dAppsList
		}
	}

	typealias Action = FeatureAction<Self>

	@CasePathable
	enum ViewAction: Sendable, Equatable {
		case task
		case didSelectDapp(State.DApp.ID)
	}

	enum InternalAction: Sendable, Equatable {
		case loadedDapps([State.DApp])
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
			let addresses = state.dAppsList
			return .run { send in
				let dApps = try await onLedgerEntitiesClient.getAssociatedDapps(addresses.elements)
				await send(.internal(.loadedDapps(
					dApps.map(State.DApp.init(dAppDetails:))
				)))
			}
		case let .didSelectDapp(dAppID):
			state.destination = .presentedDapp(.init(dAppDefinitionAddress: dAppID))
			return .none
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .loadedDapps(dApps):
			state.dAppDetails = .success(dApps.asIdentified())
			return .none
		}
	}
}

extension DAppsList.State.DApp {
	init(dAppDetails: OnLedgerEntity.AssociatedDapp) {
		self.init(
			dAppDefinitionAddress: dAppDetails.address,
			name: dAppDetails.metadata.name ?? L10n.DAppRequest.Metadata.unknownName,
			thumbnail: dAppDetails.metadata.iconURL,
			description: dAppDetails.metadata.description,
			hasClaim: false
		)
	}
}
