import ComposableArchitecture

// MARK: - PrimaryRoleSetup
@Reducer
struct PrimaryRoleSetup: FeatureReducer, Sendable {
	@ObservableState
	struct State: Hashable, Sendable {
		@Shared(.shieldBuilder) var shieldBuilder

		var factorSourcesFromProfile: [FactorSource] = []
		var isOverrideSectionExpanded = false

		@Presents
		var destination: Destination.State? = nil
	}

	typealias Action = FeatureAction<Self>

	@CasePathable
	enum ViewAction: Equatable, Sendable {
		case task
		case continueButtonTapped
		case addFactorSourceButtonTapped(ChooseFactorSourceContext)
		case removeThresholdFactorTapped(FactorSourceID)
		case removeOverrideFactorTapped(FactorSourceID)
		case removeAuthenticationSigningFactorTapped
		case showOverrideSectionButtonTapped
		case hideOverrideSectionButtonTapped
		case thresholdSelectorButtonTapped
		case invalidCombinationReadMoreTapped
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

		case let .removeThresholdFactorTapped(id):
			state.$shieldBuilder.withLock { builder in
				builder = builder.removeFactorFromPrimary(factorSourceId: id, factorListKind: .threshold)
			}
			return .none

		case let .removeOverrideFactorTapped(id):
			state.$shieldBuilder.withLock { builder in
				builder = builder.removeFactorFromPrimary(factorSourceId: id, factorListKind: .override)
			}
			return .none

		case .removeAuthenticationSigningFactorTapped:
			state.$shieldBuilder.withLock { builder in
				builder = builder.setAuthenticationSigningFactor(new: nil)
			}
			return .none

		case .showOverrideSectionButtonTapped:
			state.isOverrideSectionExpanded = true
			return .none

		case .hideOverrideSectionButtonTapped:
			state.isOverrideSectionExpanded = false
			state.$shieldBuilder.withLock { builder in
				// TODO: use removeAllFactorsFromPrimaryOverride
				for overrideFactor in state.overrideFactors {
					builder = builder.removeFactorFromPrimary(factorSourceId: overrideFactor.factorSourceID, factorListKind: .override)
				}
			}
			return .none

		case .thresholdSelectorButtonTapped:
			state.destination = .selectNumberOfFactorsView
			return .none

		case let .addFactorSourceButtonTapped(context):
			return .send(.delegate(.chooseFactorSource(context)))

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
		case let .selectNumberOfFactorsView(.set(threshold)):
			state.destination = nil
			state.$shieldBuilder.withLock { builder in
				builder = builder.setThreshold(threshold: threshold)
			}
			return .none
		}
	}
}
