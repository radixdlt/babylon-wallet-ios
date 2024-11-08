// MARK: - HideResource
@Reducer
struct HideResource: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		let kind: Kind
		var shouldShow = true

		@Presents
		var destination: Destination.State? = nil

		init(kind: Kind) {
			self.kind = kind
		}

		enum Kind: Hashable, Sendable {
			case fungible(ResourceAddress)
			case nonFungible(ResourceAddress, name: String?)
			case poolUnit(PoolAddress)
		}

		var resource: ResourceIdentifier {
			switch kind {
			case let .fungible(address): .fungible(address)
			case let .nonFungible(address, _): .nonFungible(address)
			case let .poolUnit(address): .poolUnit(address)
			}
		}
	}

	typealias Action = FeatureAction<Self>

	enum InternalAction: Sendable, Equatable {
		case setShouldShow(Bool)
	}

	enum ViewAction: Sendable, Equatable {
		case task
		case buttonTapped
	}

	enum DelegateAction: Sendable, Equatable {
		case didHideResource
	}

	// MARK: - Destination
	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Hashable, Sendable {
			case confirmation
		}

		@CasePathable
		enum Action: Equatable, Sendable {
			case confirmation(ConfirmationAction)
		}

		var body: some ReducerOf<Self> {
			EmptyReducer()
		}
	}

	@Dependency(\.resourcesVisibilityClient) var resourcesVisibilityClient
	@Dependency(\.gatewaysClient) var gatewaysClient

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			return shouldShowEffect(state: state)

		case .buttonTapped:
			state.destination = .confirmation
			return .none
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .setShouldShow(value):
			state.shouldShow = value
			return .none
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .confirmation(.confirm):
			state.destination = nil
			return hideResourceEffect(state: state)
		case .confirmation(.cancel):
			state.destination = nil
			return .none
		}
	}
}

private extension HideResource {
	func shouldShowEffect(state: State) -> Effect<Action> {
		.run { send in
			let isXrd: Bool
			switch state.resource {
			case let .fungible(resource):
				let networkId = await gatewaysClient.getCurrentNetworkID()
				isXrd = resource.isXRD(on: networkId)
			case .nonFungible, .poolUnit:
				isXrd = false
			}
			if isXrd {
				await send(.internal(.setShouldShow(false)))
			} else {
				let isAlreadyHidden = try await resourcesVisibilityClient.isHidden(state.resource)
				await send(.internal(.setShouldShow(!isAlreadyHidden)))
			}
		}
	}

	func hideResourceEffect(state: State) -> Effect<Action> {
		.run { send in
			try await resourcesVisibilityClient.hide(state.resource)
			await send(.delegate(.didHideResource))
		}
	}
}
