import ComposableArchitecture

// MARK: - RecoveryRoleSetup
@Reducer
struct RecoveryRoleSetup: FeatureReducer, Sendable {
	@ObservableState
	struct State: Hashable, Sendable {
		@Shared(.shieldBuilder) var shieldBuilder

		var factorSourcesFromProfile: [FactorSource] = []

		@Presents
		var destination: Destination.State? = nil
	}

	typealias Action = FeatureAction<Self>

	@CasePathable
	enum ViewAction: Equatable, Sendable {
		case task
		case continueButtonTapped
		case addFactorSourceButtonTapped(ChooseFactorSourceContext)
		case removeRecoveryFactorTapped(FactorSourceID)
		case removeConfirmationFactorTapped(FactorSourceID)
		case unsafeCombinationReadMoreTapped
		case selectFallbackButtonTapped
		case fallbackInfoButtonTapped
	}

	enum InternalAction: Equatable, Sendable {
		case setFactorSources([FactorSource])
	}

	enum DelegateAction: Equatable, Sendable {
		case chooseFactorSource(ChooseFactorSourceContext)
		case finished
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case selectEmergencyFallbackPeriod
			case confirmUnsafeShield(AlertState<Action.ConfirmUnsafeShield>)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case selectEmergencyFallbackPeriod(SelectEmergencyFallbackPeriodView.Action)
			case confirmUnsafeShield(ConfirmUnsafeShield)

			enum ConfirmUnsafeShield: Sendable, Hashable {
				case cancel
				case confirm
			}
		}

		var body: some ReducerOf<Self> {
			EmptyReducer()
		}
	}

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: \.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.overlayWindowClient) var overlayWindowClient
	@Dependency(\.errorQueue) var errorQueue

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			return .run { send in
				let factorSources = try await factorSourcesClient.getFactorSources().elements
				await send(.internal(.setFactorSources(factorSources)))
			} catch: { error, _ in
				errorQueue.schedule(error)
			}

		case .unsafeCombinationReadMoreTapped:
			overlayWindowClient.showInfoLink(.init(glossaryItem: .buildingshield))
			return .none

		case let .removeRecoveryFactorTapped(id):
			state.$shieldBuilder.withLock { builder in
				builder = builder.removeFactorFromRecovery(factorSourceId: id)
			}
			return .none

		case let .removeConfirmationFactorTapped(id):
			state.$shieldBuilder.withLock { builder in
				builder = builder.removeFactorFromConfirmation(factorSourceId: id)
			}
			return .none

		case let .addFactorSourceButtonTapped(context):
			return .send(.delegate(.chooseFactorSource(context)))

		case .selectFallbackButtonTapped:
			state.destination = .selectEmergencyFallbackPeriod
			return .none

		case .fallbackInfoButtonTapped:
			overlayWindowClient.showInfoLink(.init(glossaryItem: .emergencyfallback))
			return .none

		case .continueButtonTapped:
			if case .weak = state.validatedRoleStatus {
				state.destination = Destination.confirmUnsafeShieldState
				return .none
			}
			return .send(.delegate(.finished))
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .setFactorSources(factorSources):
			state.factorSourcesFromProfile = factorSources
			return .none
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .selectEmergencyFallbackPeriod(.close):
			state.destination = nil
			return .none
		case let .selectEmergencyFallbackPeriod(.set(period)):
			state.destination = nil
			state.$shieldBuilder.withLock { builder in
				builder.setTimeUntilDelayedConfirmationIsCallable(timePeriod: period)
			}
			return .none
		case .confirmUnsafeShield(.confirm):
			return .send(.delegate(.finished))
		default:
			return .none
		}
	}
}

extension RecoveryRoleSetup.Destination {
	static let confirmUnsafeShieldState: State = .confirmUnsafeShield(.init(
		title: {
			TextState("")
		},
		actions: {
			ButtonState(role: .cancel, action: .cancel) {
				TextState(L10n.ShieldSetupStatus.UnsafeCombination.cancel)
			}
			ButtonState(action: .confirm) {
				TextState(L10n.ShieldSetupStatus.UnsafeCombination.confirm)
			}
		},
		message: {
			TextState(L10n.ShieldSetupStatus.UnsafeCombination.message)
		}
	))
}
