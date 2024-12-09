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
				let message: FactorSourceCardDataSource.Message = if !entity.isMnemonicPresentInKeychain {
					.init(text: "This factor has been lost", type: .error) // Problem 9
				} else if !entity.isMnemonicMarkedAsBackedUp {
					.init(text: "Write down seed phrase to make this factor recoverable", type: .warning) // Problem 3
				} else {
					.init(text: "This seed phrase has been written down", type: .success)
				}
				return State.Row(
					factorSource: entity.deviceFactorSource,
					accounts: accounts,
					personas: personas,
					message: message
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
		let message: FactorSourceCardDataSource.Message
	}
}
