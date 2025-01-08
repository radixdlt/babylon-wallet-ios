import ComposableArchitecture

// MARK: - SelectFactorSources
@Reducer
struct RegularAccessSetup: FeatureReducer, Sendable {
	@ObservableState
	struct State: Hashable, Sendable {
		@Shared(.shieldBuilder) var shieldBuilder

		var factorSourcesFromProfile: [FactorSource] = []
		var isOverrideSectionExpanded = false
	}

	typealias Action = FeatureAction<Self>

	@CasePathable
	enum ViewAction: Equatable, Sendable {
		case task
		case continueButtonTapped
		case addThresholdFactorButtonTapped
		case addOverrideFactorButtonTapped
		case addAuthenticationSigningFactorButtonTapped
		case removeThresholdFactorTapped(FactorSourceID)
		case removeOverrideFactorTapped(FactorSourceID)
		case removeAuthenticationSigningFactorTapped
		case showOverrideSectionButtonTapped
		case hideOverrideSectionButtonTapped
	}

	enum InternalAction: Equatable, Sendable {
		case setFactorSources([FactorSource])
	}

	enum DelegateAction: Equatable, Sendable {
		case finished
	}

	var body: some ReducerOf<Self> {
		Reduce(core)
	}

	@Dependency(\.factorSourcesClient) var factorSourcesClient
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

		case let .removeThresholdFactorTapped(id):
			state.$shieldBuilder.withLock { builder in
				// TODO: use removeFactorFromPrimaryThreshold
				builder = builder.removeFactorFromPrimary(factorSourceId: id)
			}
			return .none

		case let .removeOverrideFactorTapped(id):
			state.$shieldBuilder.withLock { builder in
				// TODO: use removeFactorFromPrimaryOverride
				builder = builder.removeFactorFromPrimary(factorSourceId: id)
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
				for overrideFactor in state.overrideFactors {
					// TODO: use removeFactorFromPrimaryOverride
					builder = builder.removeFactorFromPrimary(factorSourceId: overrideFactor.factorSourceID)
				}
			}
			return .none

		// TODO:
		case .addThresholdFactorButtonTapped, .addOverrideFactorButtonTapped, .addAuthenticationSigningFactorButtonTapped:
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
}
