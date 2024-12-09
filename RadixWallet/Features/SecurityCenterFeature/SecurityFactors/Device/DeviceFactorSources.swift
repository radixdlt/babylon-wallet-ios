// MARK: - DeviceFactorSources
struct DeviceFactorSources: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		var rows: [Row] = []

		@PresentationState
		var destination: Destination.State? = nil

		fileprivate var problems: [SecurityProblem]?
		fileprivate var entities: [EntitiesControlledByFactorSource]?
	}

	enum ViewAction: Sendable, Equatable {
		case task
		case rowTapped(State.Row)
		case rowMessageTapped(State.Row)
		case addButtonTapped
	}

	enum InternalAction: Sendable, Equatable {
		case setSecurityProblems([SecurityProblem])
		case setEntities([EntitiesControlledByFactorSource])
		case setRows([State.Row])
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case detail(DeviceFactorSourceDetail.State)
			case displayMnemonic(DisplayMnemonic.State)
			case enterMnemonic(ImportMnemonicsFlowCoordinator.State)
			case addMnemonic(ImportMnemonic.State)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case detail(DeviceFactorSourceDetail.Action)
			case displayMnemonic(DisplayMnemonic.Action)
			case enterMnemonic(ImportMnemonicsFlowCoordinator.Action)
			case addMnemonic(ImportMnemonic.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.detail, action: \.detail) {
				DeviceFactorSourceDetail()
			}
			Scope(state: \.displayMnemonic, action: \.displayMnemonic) {
				DisplayMnemonic()
			}
			Scope(state: \.enterMnemonic, action: \.enterMnemonic) {
				ImportMnemonicsFlowCoordinator()
			}
			Scope(state: \.addMnemonic, action: \.addMnemonic) {
				ImportMnemonic()
			}
		}
	}

	@Dependency(\.securityCenterClient) var securityCenterClient
	@Dependency(\.deviceFactorSourceClient) var deviceFactorSourceClient
	@Dependency(\.errorQueue) var errorQueue

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			return securityProblemsEffect()
				.merge(with: entitiesEffect())

		case .rowTapped:
			state.destination = .detail(.init())
			return .none

		case let .rowMessageTapped(row):
			switch row.status {
			case .noProblem:
				return .none
			case .hasProblem3:
				return exportMnemonic(factorSourceID: row.factorSource.id) {
					state.destination = .displayMnemonic(.export($0, title: L10n.RevealSeedPhrase.title, context: .fromSettings))
				}
			case .hasProblem9:
				state.destination = .enterMnemonic(.init())
				return .none
			}

		case .addButtonTapped:
			state.destination = .addMnemonic(
				.init(
					header: .init(title: "what should be the title here?"),
					showCloseButton: false,
					isWordCountFixed: true,
					persistStrategy: .init(
						factorSourceKindOfMnemonic: .babylon(isMain: false),
						location: .intoKeychainAndProfile,
						onMnemonicExistsStrategy: .appendWithCryptoParamaters
					),
					wordCount: .twentyFour
				)
			)
			return .none
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

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .displayMnemonic(.delegate), .enterMnemonic(.delegate), .addMnemonic(.delegate):
			// We don't care about which delegate action was executed, since any corresponding
			// updates to the warnings will be handled by securityProblemsEffect.
			// We just need to dismiss the destination.
			state.destination = nil
			return .none

		default:
			return .none
		}
	}
}

private extension DeviceFactorSources {
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

	func entitiesEffect() -> Effect<Action> {
		.run { send in
			let result = try await deviceFactorSourceClient.controlledEntities(
				// `nil` means read profile in ProfileStore, instead of using an overriding profile
				nil
			)
			await send(.internal(.setEntities(result.elements)))
		} catch: { error, _ in
			errorQueue.schedule(error)
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
				let status: State.Status = if problems.hasProblem3(accounts: accounts, personas: personas) {
					.hasProblem3
				} else if problems.hasProblem9(accounts: accounts, personas: personas) || !entity.isMnemonicPresentInKeychain {
					// We need to do the trailing check because the SecurityCenterClient won't return `.problem9` if the user
					// has a DeviceFactorSource whose seed phrase is not present in keychain but doesn't have any entity associated.
					// The only way to reproduce this, is to restore a Wallet from a Profile without entering its seed phrase (so it creates a new one)
					// and not backup the new seed phrase nor create an entity.
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
extension DeviceFactorSources.State {
	struct Row: Sendable, Hashable {
		let factorSource: DeviceFactorSource
		let accounts: [Account]
		let personas: [Persona]
		let status: Status
	}

	enum Status: Sendable, Hashable {
		case hasProblem3
		case hasProblem9
		case noProblem
	}
}
