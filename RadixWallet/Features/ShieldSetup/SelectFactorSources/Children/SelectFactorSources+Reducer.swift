import ComposableArchitecture

// MARK: - SelectFactorSources
@Reducer
struct SelectFactorSources: FeatureReducer, Sendable {
	@ObservableState
	struct State: Hashable, Sendable {
		@Shared(.shieldBuilder) var shieldBuilder

		/// Factor sources from the profile, sorted and filtered for eligibility in the primary threshold role
		var factorSourcesCandidates: [FactorSource] = []
		var selectedFactorSources: [FactorSource]? {
			factorSourcesCandidates.filter { shieldBuilder.primaryRoleThresholdFactors.contains($0.factorSourceID) }
		}

		var didInteractWithSelection = false

		init() {
			$shieldBuilder.initialize()
		}
	}

	typealias Action = FeatureAction<Self>

	@CasePathable
	enum ViewAction: Equatable, Sendable {
		case onFirstAppear
		case selectedFactorSourcesChanged([FactorSource]?)
		case continueButtonTapped
		case invalidReadMoreTapped
		case skipButtonTapped
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
	@Dependency(\.overlayWindowClient) var overlayWindowClient
	@Dependency(\.errorQueue) var errorQueue

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .onFirstAppear:
			return .run { [shieldBuilder = state.shieldBuilder] send in
				let factorSources = try await factorSourcesClient.getFactorSources().elements
				let result = shieldBuilder.sortedFactorSourcesForPrimaryThresholdSelection(factorSources: factorSources)
				await send(.internal(.setFactorSources(result)))
			} catch: { error, _ in
				errorQueue.schedule(error)
			}

		case let .selectedFactorSourcesChanged(factorSources):
			let difference = (factorSources ?? []).difference(from: state.selectedFactorSources ?? [])

			for change in difference {
				state.$shieldBuilder.withLock { builder in
					switch change {
					case let .remove(_, factorSource, _):
						builder = builder.removeFactorFromPrimary(factorSourceId: factorSource.factorSourceID, factorListKind: .threshold)
					case let .insert(_, factorSource, _):
						builder = builder.addFactorSourceToPrimaryThreshold(factorSourceId: factorSource.factorSourceID)
					}
				}
			}

			if !state.didInteractWithSelection, !difference.isEmpty {
				state.didInteractWithSelection = true
			}

			return .none

		case .continueButtonTapped:
			state.$shieldBuilder.withLock { builder in
				builder = builder.autoAssignFactorsToRecoveryAndConfirmationBasedOnPrimary(allFactors: state.factorSourcesCandidates)
			}
			return .send(.delegate(.finished))

		case .invalidReadMoreTapped:
			overlayWindowClient.showInfoLink(.init(glossaryItem: .buildingshield))
			return .none

		case .skipButtonTapped:
			state.$shieldBuilder.initialize()
			return .send(.delegate(.finished))
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .setFactorSources(factorSources):
			state.factorSourcesCandidates = factorSources
			return .none
		}
	}
}

// MARK: - ShieldStatusMessageInfo
struct ShieldStatusMessageInfo: Hashable, Sendable {
	let type: StatusMessageView.ViewType
	let text: String
}
