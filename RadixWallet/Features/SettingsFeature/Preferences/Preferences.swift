// MARK: - Preferences

public struct Preferences: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var appPreferences: AppPreferences?

		@PresentationState
		public var destination: Destination.State?

		public init() {}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case depositGuaranteesButtonTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case loadedAppPreferences(AppPreferences)
	}

	public struct Destination: DestinationReducer {
		public enum State: Sendable, Hashable {
			case depositGuarantees(DefaultDepositGuarantees.State)
		}

		public enum Action: Sendable, Equatable {
			case depositGuarantees(DefaultDepositGuarantees.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.depositGuarantees, action: /Action.depositGuarantees) {
				DefaultDepositGuarantees()
			}
		}
	}

	@Dependency(\.appPreferencesClient) var appPreferencesClient

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
			return .run { send in
				let appPreferences = await appPreferencesClient.getPreferences()
				await send(.internal(.loadedAppPreferences(appPreferences)))
			}

		case .depositGuaranteesButtonTapped:
			let depositGuarantee = state.appPreferences?.transaction.defaultDepositGuarantee ?? 1
			state.destination = .depositGuarantees(.init(depositGuarantee: depositGuarantee))
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .loadedAppPreferences(appPreferences):
			state.appPreferences = appPreferences
			return .none
		}
	}

	public func reduceDismissedDestination(into state: inout State) -> Effect<Action> {
		if
			case let .depositGuarantees(depositGuarantees) = state.destination,
			let value = depositGuarantees.depositGuarantee
		{
			state.appPreferences?.transaction.defaultDepositGuarantee = value
			return savePreferences(state: state)
		}
		return .none
	}

	private func savePreferences(state: State) -> Effect<Action> {
		guard let preferences = state.appPreferences else { return .none }
		return .run { _ in
			try await appPreferencesClient.updatePreferences(preferences)
		}
	}
}
