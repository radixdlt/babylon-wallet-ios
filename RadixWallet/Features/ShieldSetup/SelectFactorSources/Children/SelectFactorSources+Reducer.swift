import ComposableArchitecture

// MARK: - SelectFactorSources
@Reducer
struct SelectFactorSources: FeatureReducer, Sendable {
	@ObservableState
	struct State: Hashable, Sendable {
		@Shared(.shieldBuilder) var shieldBuilder
		var factorSources: [FactorSource] = []
		var selectedFactorSources: [FactorSource]? {
			factorSources.filter { shieldBuilder.primaryRoleThresholdFactors.contains($0.factorSourceID) }
		}

		var didInteractWithSelection = false

		init() {
			$shieldBuilder.initialize()
		}
	}

	typealias Action = FeatureAction<Self>

	@CasePathable
	enum ViewAction: Equatable, Sendable {
		case task
		case selectedFactorSourcesChanged([FactorSource]?)
		case continueButtonTapped
		case invalidReadMoreTapped
	}

	enum InternalAction: Equatable, Sendable {
		case factorSourcesResult(TaskResult<[FactorSource]>)
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
		case .task:
			return .run { [shieldBuilder = state.shieldBuilder] send in
				let result = await TaskResult {
					let factorSources = try await factorSourcesClient.getFactorSources().elements
					return shieldBuilder.sortedFactorSourcesForPrimaryThresholdSelection(factorSources: factorSources)
				}
				await send(.internal(.factorSourcesResult(result)))
			}

		case let .selectedFactorSourcesChanged(factorSources):
			let difference = (factorSources ?? []).difference(from: state.selectedFactorSources ?? [])

			for change in difference {
				state.$shieldBuilder.withLock { builder in
					switch change {
					case let .remove(_, factorSource, _):
						builder = builder.removeFactorFromPrimary(factorSourceId: factorSource.factorSourceID)
					case let .insert(_, factorSource, _):
						builder = builder.addFactorSourceToPrimaryThreshold(factorSourceId: factorSource.factorSourceID)
					}
				}
			}

			// TODO: Remove once https://radixdlt.atlassian.net/browse/ABW-4047 is implemented
			state.$shieldBuilder.withLock { builder in
				builder = builder.setThreshold(threshold: UInt8(builder.primaryRoleThresholdFactors.count))
			}

			if !state.didInteractWithSelection, !difference.isEmpty {
				state.didInteractWithSelection = true
			}

			return .none

		case .continueButtonTapped:
			return .send(.delegate(.finished))

		case .invalidReadMoreTapped:
			overlayWindowClient.showInfoLink(.init(glossaryItem: .buildingshield))
			return .none
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .factorSourcesResult(.success(factorSources)):
			state.factorSources = factorSources
			return .none
		case let .factorSourcesResult(.failure(error)):
			errorQueue.schedule(error)
			return .none
		}
	}
}

// MARK: - SelectFactorSources.State.StatusMessageInfo
extension SelectFactorSources.State {
	struct StatusMessageInfo: Hashable, Sendable {
		let type: StatusMessageView.ViewType
		let text: String
	}
}
