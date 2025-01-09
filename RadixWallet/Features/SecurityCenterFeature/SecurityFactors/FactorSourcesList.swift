// MARK: - FactorSourcesList
@Reducer
struct FactorSourcesList: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		let context: Context
		let kind: FactorSourceKind
		var rows: [Row] = []
		var selected: Row?

		init(context: Context = .display, kind: FactorSourceKind) {
			self.context = context
			self.kind = kind
		}

		@Presents
		var destination: Destination.State? = nil

		fileprivate var problems: [SecurityProblem]?
		fileprivate var entities: [EntitiesLinkedToFactorSource]?
	}

	typealias Action = FeatureAction<Self>

	enum ViewAction: Sendable, Equatable {
		case task
		case rowTapped(State.Row)
		case rowMessageTapped(State.Row)
		case addButtonTapped
		case continueButtonTapped
	}

	enum InternalAction: Sendable, Equatable {
		case setSecurityProblems([SecurityProblem])
		case setEntities([EntitiesLinkedToFactorSource])
	}

	enum DelegateAction: Sendable, Equatable {
		case selectedFactorSource(FactorSource)
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case detail(FactorSourceDetail.State)
			case displayMnemonic(DisplayMnemonic.State)
			case enterMnemonic(ImportMnemonicsFlowCoordinator.State)
			case addMnemonic(ImportMnemonic.State)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case detail(FactorSourceDetail.Action)
			case displayMnemonic(DisplayMnemonic.Action)
			case enterMnemonic(ImportMnemonicsFlowCoordinator.Action)
			case addMnemonic(ImportMnemonic.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.detail, action: \.detail) {
				FactorSourceDetail()
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
	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.errorQueue) var errorQueue

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: \.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			return securityProblemsEffect()
				.merge(with: entitiesEffect(state: state))

		case let .rowTapped(row):
			switch state.context {
			case .display:
				state.destination = .detail(.init(integrity: row.integrity))
			case .selection:
				state.selected = row
			}
			return .none

		case let .rowMessageTapped(row):
			switch row.status {
			case .seedPhraseWrittenDown, .notBackedUp:
				return .none

			case .seedPhraseNotRecoverable:
				return exportMnemonic(integrity: row.integrity) {
					state.destination = .displayMnemonic(.export($0, title: L10n.RevealSeedPhrase.title, context: .fromSettings))
				}

			case .lostFactorSource:
				state.destination = .enterMnemonic(.init())
				return .none
			}

		case .addButtonTapped:
			switch state.kind {
			case .device:
				state.destination = .addMnemonic(
					.init(
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
			case .ledgerHqHardwareWallet, .offDeviceMnemonic, .arculusCard, .password:
				// NOTE: Added `.device` support as placeholder, but not adding the logic for ledger (which we already support)
				// since Matt mentioned we will probably always present this screen: https://zpl.io/wyqB6Bd
				// and I don't want to add all the logic for checking if there is a CE or not just to migrate it later.
				loggerGlobal.info("Add \(state.kind) not yet implemented")
			case .trustedContact, .securityQuestions:
				fatalError("Not supported")
			}

			return .none

		case .continueButtonTapped:
			guard let selected = state.selected?.integrity.factorSource else {
				return .none
			}
			return .send(.delegate(.selectedFactorSource(selected)))
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

private extension FactorSourcesList {
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
			let result = try await factorSourcesClient.entitiesLinkedToFactorSourceKind(kind: state.kind)
			await send(.internal(.setEntities(result)))
		} catch: { error, _ in
			errorQueue.schedule(error)
		}
	}

	func setRows(state: inout State) {
		guard let problems = state.problems, let entities = state.entities else {
			return
		}
		state.rows = entities.map { entity in
			let accounts = entity.accounts + entity.hiddenAccounts
			let personas = entity.personas
			let status: State.Status = if problems.hasProblem9(accounts: accounts, personas: personas) {
				.lostFactorSource
			} else if problems.hasProblem3(accounts: accounts, personas: personas) {
				.seedPhraseNotRecoverable
			} else if entity.integrity.isMnemonicMarkedAsBackedUp {
				.seedPhraseWrittenDown
			} else {
				// A way to reproduce this, is to restore a Wallet from a Profile without entering its seed phrase (so it creates a new one)
				// and do not write down the new seed phrase nor create an entity. In such case, we don't want to show problem3 because the
				// non-backed up factor source didn't create any entity. Yet, we don't want to show the success checkmark indicating the factor
				// source was backed up.
				.notBackedUp
			}
			return State.Row(
				integrity: entity.integrity,
				linkedEntities: entity.linkedEntities,
				status: status
			)
		}
	}
}

// MARK: - DeviceFactorSourcesList.State.Row
extension FactorSourcesList.State {
	enum Context: Sendable, Hashable {
		case display
		case selection
	}

	struct Row: Sendable, Hashable, Identifiable {
		let integrity: FactorSourceIntegrity
		let linkedEntities: FactorSourceCardDataSource.LinkedEntities
		let status: Status

		var id: FactorSourceID {
			integrity.factorSource.id
		}
	}

	enum Status: Sendable, Hashable {
		/// User has lost access to the given factor source (`SecurityProblem.problem9`).
		/// We will show an error message.
		case lostFactorSource

		/// User has access to the factor source, which has associated entities, but hasn't been backed up (`SecurityProblem.problem3`).
		/// We will show a warning message.
		case seedPhraseNotRecoverable

		/// User has access to the factor source, which has associated entities, and has backed it up.
		/// We will show a success message.
		case seedPhraseWrittenDown

		/// User has access to the factor source, which doesn't have associated entities, and hasn't been backed up.
		/// We won't show any message (since there are no entities associated).
		case notBackedUp
	}
}

private extension EntitiesLinkedToFactorSource {
	var linkedEntities: FactorSourceCardDataSource.LinkedEntities {
		.init(accounts: accounts, personas: personas, hasHiddenEntities: !hiddenAccounts.isEmpty || !hiddenPersonas.isEmpty)
	}
}

private extension FactorSourceIntegrity {
	var isMnemonicMarkedAsBackedUp: Bool {
		switch self {
		case let .device(device):
			device.isMnemonicMarkedAsBackedUp
		case .ledger, .offDeviceMnemonic, .arculusCard, .password:
			false
		}
	}
}
