import ComposableArchitecture

// MARK: - HiddenEntities
@Reducer
public struct HiddenEntities: Sendable, FeatureReducer {
	@ObservableState
	public struct State: Sendable, Hashable {
		var personas: Personas = []
		var accounts: Accounts = []

		@Presents
		var destination: Destination.State? = nil
	}

	public typealias Action = FeatureAction<Self>

	@CasePathable
	public enum ViewAction: Sendable, Equatable {
		case task
		case unhidePersonaTapped(Persona.ID)
		case unhideAccountTapped(Account.ID)
	}

	public enum InternalAction: Sendable, Equatable {
		case setEntities(EntitiesVisibilityClient.HiddenEntities)
		case didUnhidePersona(Persona.ID)
		case didUnhideAccount(Account.ID)
	}

	public struct Destination: DestinationReducer {
		@CasePathable
		public enum State: Sendable, Hashable {
			case unhideAlert(AlertState<Action.UnhideAlert>)
		}

		@CasePathable
		public enum Action: Sendable, Equatable {
			case unhideAlert(UnhideAlert)

			public enum UnhideAlert: Hashable, Sendable {
				case confirmPersonaTapped(Persona.ID)
				case confirmAccountTapped(Account.ID)
				case cancelTapped
			}
		}

		public var body: some ReducerOf<Self> {
			EmptyReducer()
		}
	}

	@Dependency(\.entitiesVisibilityClient) var entitiesVisibilityClient

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce(core)
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			return .run { send in
				let hiddenEntities = try await entitiesVisibilityClient.getHiddenEntities()
				await send(.internal(.setEntities(hiddenEntities)))
			}
		case let .unhidePersonaTapped(personaId):
			state.destination = .unhideAlert(.init(
				title: { TextState(L10n.HiddenEntities.unhidePersonasConfirmation) },
				actions: {
					ButtonState(role: .cancel, action: .cancelTapped) {
						TextState(L10n.Common.cancel)
					}
					ButtonState(action: .confirmPersonaTapped(personaId)) {
						TextState(L10n.Common.confirm)
					}
				}
			))
			return .none
		case let .unhideAccountTapped(accountId):
			state.destination = .unhideAlert(.init(
				title: { TextState(L10n.HiddenEntities.unhideAccountsConfirmation) },
				actions: {
					ButtonState(role: .cancel, action: .cancelTapped) {
						TextState(L10n.Common.cancel)
					}
					ButtonState(action: .confirmAccountTapped(accountId)) {
						TextState(L10n.Common.confirm)
					}
				}
			))
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .setEntities(hiddenEntities):
			state.personas = hiddenEntities.personas
			state.accounts = hiddenEntities.accounts
			return .none

		case let .didUnhidePersona(personaId):
			state.personas.remove(id: personaId)
			state.destination = nil
			return .none

		case let .didUnhideAccount(accountId):
			state.accounts.remove(id: accountId)
			state.destination = nil
			return .none
		}
	}

	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case let .unhideAlert(action):
			switch action {
			case let .confirmPersonaTapped(personaId):
				return .run { send in
					try await entitiesVisibilityClient.unhidePersona(personaId)
					await send(.internal(.didUnhidePersona(personaId)), animation: .default)
				}
			case let .confirmAccountTapped(accountId):
				return .run { send in
					try await entitiesVisibilityClient.unhideAccount(accountId)
					await send(.internal(.didUnhideAccount(accountId)), animation: .default)
				}
			case .cancelTapped:
				state.destination = nil
				return .none
			}
		}
	}
}
