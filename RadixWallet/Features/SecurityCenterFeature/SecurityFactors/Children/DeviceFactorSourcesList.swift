// MARK: - DeviceFactorSourcesList
struct DeviceFactorSourcesList: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		var rows: [Row] = []

		fileprivate var problems: [SecurityProblem]?
		fileprivate var entities: [EntitiesControlledByFactorSource]?
	}

	enum ViewAction: Sendable, Equatable {
		case task
	}

	enum InternalAction: Sendable, Equatable {
		case setSecurityProblems([SecurityProblem])
		case setEntities([EntitiesControlledByFactorSource])
		case setRows([State.Row])
	}

	@Dependency(\.securityCenterClient) var securityCenterClient
	@Dependency(\.deviceFactorSourceClient) var deviceFactorSourceClient

	func reduce(into _: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			securityProblemsEffect()
				.merge(with: entitiesEffect())
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .setSecurityProblems(problems):
			state.problems = problems
			return rowsEffect(state: state)

		case let .setEntities(entities):
			state.entities = entities
			return rowsEffect(state: state)

		case let .setRows(rows):
			state.rows = rows
			return .none
		}
	}
}

private extension DeviceFactorSourcesList {
	func securityProblemsEffect() -> Effect<Action> {
		.run { send in
			for try await problems in await securityCenterClient.problems(.securityFactors) {
				guard !Task.isCancelled else { return }
				await send(.internal(.setSecurityProblems(problems)))
			}
		}
	}

	func entitiesEffect() -> Effect<Action> {
		.run { send in
			let result = try await deviceFactorSourceClient.controlledEntities(
				// `nil` means read profile in ProfileStore, instead of using an overriding profile
				nil
			)
			await send(.internal(.setEntities(result.elements)))
		}
	}

	func rowsEffect(state: State) -> Effect<Action> {
		guard let problems = state.problems, let entities = state.entities else {
			return .none
		}
		return .run { send in
			let rows = entities.map { entity in
				let accounts = entity.accounts + entity.hiddenAccounts
				let personas = entity.personas
				let status: State.Row.Status = if problems.hasProblem3(accounts: accounts, personas: personas) {
					.hasProblem3
				} else if problems.hasProblem9(accounts: accounts, personas: personas) {
					.hasProblem9
				} else {
					.noProblem
				}
				return State.Row(
					factorSource: entity.deviceFactorSource,
					accounts: accounts,
					personas: personas,
					status: status
				)
			}
			await send(.internal(.setRows(rows)))
		}
	}
}

// MARK: - DeviceFactorSourcesList.State.Row
extension DeviceFactorSourcesList.State {
	struct Row: Sendable, Hashable {
		let factorSource: DeviceFactorSource
		let accounts: [Account]
		let personas: [Persona]
		let status: Status

		enum Status: Sendable, Hashable {
			case hasProblem3
			case hasProblem9
			case noProblem
		}
	}
}
