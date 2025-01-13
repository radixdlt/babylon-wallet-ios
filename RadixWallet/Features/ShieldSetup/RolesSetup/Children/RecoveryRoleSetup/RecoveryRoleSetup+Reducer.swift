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
		case removeAuthenticationSigningFactorTapped
		case thresholdSelectorButtonTapped
		case invalidCombinationReadMoreTapped
		case setFallbackButtonTapped
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
			case selectNumberOfFactorsView
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case selectNumberOfFactorsView(SelectNumberOfFactorsView.Action)
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

		case .invalidCombinationReadMoreTapped:
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

		case .removeAuthenticationSigningFactorTapped:
			state.$shieldBuilder.withLock { builder in
				builder = builder.setAuthenticationSigningFactor(new: nil)
			}
			return .none

		case .thresholdSelectorButtonTapped:
			state.destination = .selectNumberOfFactorsView
			return .none

		case let .addFactorSourceButtonTapped(context):
			return .send(.delegate(.chooseFactorSource(context)))

		case .setFallbackButtonTapped:
			return .none

		case .fallbackInfoButtonTapped:
			overlayWindowClient.showInfoLink(.init(glossaryItem: .buildingshield)) // TODO: add corresponding GlossaryItem
			return .none

		case .continueButtonTapped:
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
		case .selectNumberOfFactorsView(.close):
			state.destination = nil
			return .none
		case let .selectNumberOfFactorsView(.set(value)):
			state.destination = nil
			state.$shieldBuilder.withLock { builder in
				switch value {
				case .all:
					builder = builder.setThreshold(threshold: UInt8(builder.primaryRoleThresholdFactors.count))
				case let .specific(numberOfFactors):
					builder = builder.setThreshold(threshold: UInt8(numberOfFactors))
				}
			}
			return .none
		}
	}
}
