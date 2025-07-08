// MARK: - SelectFactorSource
@Reducer
struct SelectFactorSource: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		let kinds: [FactorSourceKind]

		var rows: [FactorSourcesList.Row] = []
		var selectedFactorSource: FactorSourcesList.Row?
		var problems: [SecurityProblem]?
		var entities: [EntitiesLinkedToFactorSource]?

		var hasAConnectorExtension: Bool = false

		@Presents
		var destination: Destination.State? = nil
	}

	typealias Action = FeatureAction<Self>

	@CasePathable
	enum ViewAction: Sendable, Equatable {
		case appeared
		case addSecurityFactorTapped
		case rowTapped(FactorSourcesList.Row?)
		case continueButtonTapped(FactorSourcesList.Row)
	}

	enum InternalAction: Equatable, Sendable {
		case setSecurityProblems([SecurityProblem])
		case setEntities([EntitiesLinkedToFactorSource])
		case hasAConnectorExtension(Bool)
	}

	enum DelegateAction: Equatable, Sendable {
		case selectedFactorSource(FactorSource)
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Hashable, Sendable {
			case addSecurityFactor(AddFactorSource.Coordinator.State)
			case addNewP2PLink(NewConnection.State)
		}

		@CasePathable
		enum Action: Equatable, Sendable {
			case addSecurityFactor(AddFactorSource.Coordinator.Action)
			case addNewP2PLink(NewConnection.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.addSecurityFactor, action: \.addSecurityFactor) {
				AddFactorSource.Coordinator()
			}

			Scope(state: \.addNewP2PLink, action: \.addNewP2PLink) {
				NewConnection()
			}
		}
	}

	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.securityCenterClient) var securityCenterClient
	@Dependency(\.ledgerHardwareWalletClient) var ledgerHardwareWalletClient
	@Dependency(\.errorQueue) var errorQueue

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	init() {}

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: \.destination) {
				Destination()
			}
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			return securityProblemsEffect()
				.merge(with: entitiesEffect(state: state))
				.merge(with: checkP2PLinkEffect())

		case let .rowTapped(factorSource):
			state.selectedFactorSource = factorSource
			return .none

		case let .continueButtonTapped(row):
			if row.integrity.factorSource.kind == .ledgerHqHardwareWallet, !state.hasAConnectorExtension {
				state.destination = .addNewP2PLink(.init(root: .ledgerConnectionIntro))
				return .none
			}
			return .send(.delegate(.selectedFactorSource(row.integrity.factorSource)))

		case .addSecurityFactorTapped:
			state.destination = .addSecurityFactor(.init(mode: .toSelectFromKinds(state.kinds)))
			return .none
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .setSecurityProblems(problems):
			state.problems = problems
			setRows(state: &state)
			return .none

		case let .setEntities(entities):
			state.entities = entities
			setRows(state: &state)
			return .none

		case let .hasAConnectorExtension(hasCE):
			state.hasAConnectorExtension = hasCE
			return .none
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .addSecurityFactor(.delegate(.finished)):
			state.destination = nil
			return entitiesEffect(state: state)
		case .addNewP2PLink(.delegate(.newConnection)):
			state.destination = nil
			guard let selectedFactorSource = state.selectedFactorSource?.integrity.factorSource else {
				return .none
			}
			return .send(.delegate(.selectedFactorSource(selectedFactorSource)))
		default:
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

	private func checkP2PLinkEffect() -> Effect<Action> {
		.run { send in
			let hasAConnectorExtension = await ledgerHardwareWalletClient.hasAnyLinkedConnector()
			await send(.internal(.hasAConnectorExtension(hasAConnectorExtension)))
		} catch: { error, _ in
			loggerGlobal.error("failed to get links updates, error: \(error)")
		}
	}
}
