// MARK: - SelectFactorSource
@Reducer
struct SelectFactorSource: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		var factorSourcesCandidates: [FactorSource] = []
		var rows: [FactorSourcesList.Row] = []

		var selectedFactorSource: FactorSourcesList.Row?

		fileprivate var problems: [SecurityProblem]?
		fileprivate var entities: [EntitiesLinkedToFactorSource]?
	}

	typealias Action = FeatureAction<Self>

	@CasePathable
	enum ViewAction: Sendable, Equatable {
		case appeared
		case rowTapped(FactorSourcesList.Row?)
		case continueButtonTapped(FactorSourcesList.Row)
	}

	enum InternalAction: Equatable, Sendable {
		case setFactorSources([FactorSource])
		case setSecurityProblems([SecurityProblem])
		case setEntities([EntitiesLinkedToFactorSource])
	}

	enum DelegateAction: Equatable, Sendable {
		case selectedFactorSource(FactorSource)
	}

	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.securityCenterClient) var securityCenterClient
	@Dependency(\.errorQueue) var errorQueue

	var body: some ReducerOf<Self> {
		Reduce(core)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			return securityProblemsEffect()
				.merge(with: entitiesEffect(state: state))

		case let .rowTapped(factorSource):
			state.selectedFactorSource = factorSource
			return .none

		case let .continueButtonTapped(row):
			return .send(.delegate(.selectedFactorSource(row.integrity.factorSource)))
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .setFactorSources(factorSources):
			state.factorSourcesCandidates = factorSources
			return .none

		case let .setSecurityProblems(problems):
			state.problems = problems
			setRows(state: &state)
			return .none

		case let .setEntities(entities):
			state.entities = entities
			setRows(state: &state)
			return .none
		}
	}

	func setRows(state: inout State) {
		guard let problems = state.problems, let entities = state.entities else {
			return
		}
		state.rows = entities.map { entity in
			let status = FactorSourcesList.Row.Status(entity: entity, problems: problems)
			return FactorSourcesList.Row(
				integrity: entity.integrity,
				linkedEntities: entity.linkedEntities,
				status: status,
				selectability: status == .lostFactorSource ? .unselectable : .selectable
			)
		}.sorted { lhs, rhs in
			if lhs.integrity.factorSource.kind == rhs.integrity.factorSource.kind {
				lhs.integrity.factorSource.lastUsedOn > rhs.integrity.factorSource.lastUsedOn
			} else {
				false
			}
		}
	}

	func securityProblemsEffect() -> Effect<Action> {
		.run { send in
			for try await problems in await securityCenterClient.problems(.securityFactors) {
				guard !Task.isCancelled else { return }
				await send(.internal(.setSecurityProblems(problems)))
			}
		} catch: { error, _ in
			errorQueue.schedule(error)
		}
	}

	func entitiesEffect(state: State) -> Effect<Action> {
		.run { send in
			let result = try await factorSourcesClient.entititesLinkedToFactorSourceKinds([.device, .ledgerHqHardwareWallet, .arculusCard])
			await send(.internal(.setEntities(result)))
		} catch: { error, _ in
			errorQueue.schedule(error)
		}
	}
}
