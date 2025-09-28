// MARK: - FactorSourcesList
@Reducer
struct FactorSourcesList: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		@SharedReader(.shieldBuilder) var shieldBuilder
		let context: Context
		let kind: FactorSourceKind
		var rows: [Row] = []
		var selected: Row?

		var hasAConnectorExtension: Bool = false
		var pendingAction: ActionRequiringP2P? = nil

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

	enum ActionRequiringP2P: Sendable, Hashable {
		case addLedger
		case continueWithFactorsource(FactorSource)
	}

	enum ViewAction: Sendable, Equatable {
		case task
		case rowTapped(Row)
		case rowMessageTapped(Row)
		case addButtonTapped
		case continueButtonTapped(FactorSource)
		case closeEnterMnemonicButtonTapped
	}

	enum InternalAction: Sendable, Equatable {
		case setSecurityProblems([SecurityProblem])
		case setEntities([EntitiesLinkedToFactorSource])
		case hasAConnectorExtension(Bool)
	}

	enum DelegateAction: Sendable, Equatable {
		case selectedFactorSource(FactorSource)
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case detail(FactorSourceDetail.State)
			case displayMnemonic(DisplayMnemonic.State)
			case enterMnemonic(ImportMnemonicForFactorSource.State)
			case noP2PLink(AlertState<NoP2PLinkAlert>)
			case addNewP2PLink(NewConnection.State)
			case addFactorSource(AddFactorSource.Coordinator.State)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case detail(FactorSourceDetail.Action)
			case displayMnemonic(DisplayMnemonic.Action)
			case enterMnemonic(ImportMnemonicForFactorSource.Action)
			case noP2PLink(NoP2PLinkAlert)
			case addNewP2PLink(NewConnection.Action)
			case addFactorSource(AddFactorSource.Coordinator.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.detail, action: \.detail) {
				FactorSourceDetail()
			}
			Scope(state: \.displayMnemonic, action: \.displayMnemonic) {
				DisplayMnemonic()
			}
			Scope(state: \.enterMnemonic, action: \.enterMnemonic) {
				ImportMnemonicForFactorSource()
			}
			Scope(state: \.addNewP2PLink, action: \.addNewP2PLink) {
				NewConnection()
			}
			Scope(state: \.addFactorSource, action: \.addFactorSource) {
				AddFactorSource.Coordinator()
			}
		}
	}

	@Dependency(\.securityCenterClient) var securityCenterClient
	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.radixConnectClient) var radixConnectClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.ledgerHardwareWalletClient) var ledgerHardwareWalletClient

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
			var effects = securityProblemsEffect()
				.merge(with: entitiesEffect(state: state))
			if state.kind == .ledgerHqHardwareWallet {
				effects = effects.merge(with: checkP2PLinkEffect())
			}
			return effects

		case let .rowTapped(row):
			switch state.context {
			case .display:
				state.destination = .detail(.init(integrity: row.integrity))
			case .selection:
				switch row.selectability {
				case .selectable:
					state.selected = row
				case .alreadySelected, .unselectable:
					break
				}
			}
			return .none

		case let .rowMessageTapped(row):
			switch row.status {
			case .seedPhraseWrittenDown, .notBackedUp:
				return .none

			case .seedPhraseNotRecoverable:
				return exportMnemonic(integrity: row.integrity) {
					state.destination = .displayMnemonic(.init(mnemonic: $0.mnemonicWithPassphrase.mnemonic, factorSourceID: $0.factorSourceID))
				}

			case .lostFactorSource:
				guard let deviceFS = row.integrity.factorSource.asDevice else {
					return .none
				}
				state.destination = .enterMnemonic(.init(deviceFactorSource: deviceFS, profileToCheck: .current))
				return .none

			case .none:
				return .none
			}

		case .addButtonTapped:
			switch state.kind {
			case .device, .arculusCard, .offDeviceMnemonic, .ledgerHqHardwareWallet:
				state.destination = .addFactorSource(
					.init(
						mode: .preselectedKind(state.kind),
						context: .newFactorSource
					)
				)
			default:
				assertionFailure("Unsupported factor source kind \(state.kind)")
			}

			return .none

		case let .continueButtonTapped(factorSource):
			if state.kind == .ledgerHqHardwareWallet {
				return performActionRequiringP2PEffect(.continueWithFactorsource(factorSource), in: &state)
			}
			return .send(.delegate(.selectedFactorSource(factorSource)))

		case .closeEnterMnemonicButtonTapped:
			state.destination = nil
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
		case let .enterMnemonic(.delegate(action)):
			// We don't care about which delegate action was executed, since any corresponding
			// updates to the warnings will be handled by securityProblemsEffect.
			// We just need to dismiss the destination.
			state.destination = nil

			if case .imported = action {
				return entitiesEffect(state: state)
			}
			return .none

		case .displayMnemonic(.delegate(.backedUp)):
			state.destination = nil
			return entitiesEffect(state: state)

		case let .noP2PLink(alertAction):
			switch alertAction {
			case .addNewP2PLinkTapped:
				state.destination = .addNewP2PLink(.init())
				return .none

			case .cancelTapped:
				return .none
			}

		case let .addNewP2PLink(.delegate(newP2PAction)):
			switch newP2PAction {
			case .newConnection:
				state.destination = nil
				return .none
			}

		case .addFactorSource(.delegate(.finished)):
			state.destination = nil
			return entitiesEffect(state: state)

		default:
			return .none
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

	private func performActionRequiringP2PEffect(_ action: ActionRequiringP2P, in state: inout State) -> Effect<Action> {
		// If we don't have a connection, we remember what we were trying to do and then ask if they want to link one
		guard state.hasAConnectorExtension else {
			state.pendingAction = action
			state.destination = .noP2PLink(.noP2Plink)
			return .none
		}

		state.pendingAction = nil

		// If we have a connection, we can proceed directly
		switch action {
		case .addLedger:
			state.destination = .addFactorSource(.init(
				mode: .preselectedKind(.ledgerHqHardwareWallet),
				context: .newFactorSource
			))
			return .none
		case let .continueWithFactorsource(fs):
			return .send(.delegate(.selectedFactorSource(fs)))
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
		let factorSourceIds = entities.map(\.integrity.factorSource.id)
		let alreadySelectedFactorSourceIds = filterAlreadySelectedFactorSourceIds(state: state, factorSourceIds: factorSourceIds)
		state.rows = entities.map { entity in
			let status = Row.Status(entity: entity, problems: problems)

			// Determine row selectability
			let selectability: Row.Selectability = if state.context == .display {
				.selectable
			} else if status == .lostFactorSource {
				.unselectable
			} else if alreadySelectedFactorSourceIds.contains(entity.integrity.factorSource.id) {
				.alreadySelected
			} else {
				.selectable
			}
			return Row(
				integrity: entity.integrity,
				linkedEntities: entity.linkedEntities,
				status: status,
				selectability: selectability
			)
		}
	}

	func filterAlreadySelectedFactorSourceIds(state: State, factorSourceIds: [FactorSourceId]) -> [FactorSourceId] {
		let status: [FactorSourceValidationStatus] =
			switch state.context {
			case .display, .selection(.authenticationSigning):
				[]
			case .selection(.primaryThreshold):
				state.shieldBuilder.validationForAdditionOfFactorSourceToPrimaryThresholdForEach(factorSources: factorSourceIds)
			case .selection(.primaryOverride):
				state.shieldBuilder.validationForAdditionOfFactorSourceToPrimaryOverrideForEach(factorSources: factorSourceIds)
			case .selection(.recovery):
				state.shieldBuilder.validationForAdditionOfFactorSourceToRecoveryOverrideForEach(factorSources: factorSourceIds)
			case .selection(.confirmation):
				state.shieldBuilder.validationForAdditionOfFactorSourceToConfirmationOverrideForEach(factorSources: factorSourceIds)
			}
		return status.compactMap { status in
			guard let reason = status.reasonIfInvalid else {
				return nil
			}
			switch reason {
			case .nonBasic(.FactorSourceAlreadyPresent):
				break
			default:
				assertionFailure("Sargon considered \(status.factorSourceId) invalid for a reason different than already selected: \(reason)")
			}
			return status.factorSourceId
		}
	}
}

// MARK: - FactorSourcesList.State.Context
extension FactorSourcesList.State {
	enum Context: Sendable, Hashable {
		case display
		case selection(ChooseFactorSourceContext)
	}
}

extension FactorSourcesList {
	struct Row: Sendable, Hashable, Identifiable {
		let integrity: FactorSourceIntegrity
		let linkedEntities: FactorSourceCardDataSource.LinkedEntities
		let status: Status?
		let selectability: Selectability

		var id: FactorSourceID {
			integrity.factorSource.id
		}
	}

	private func sort(_ lhs: FactorSourceIntegrity, _ rhs: FactorSourceIntegrity) -> Bool {
		lhs.factorSource.common.addedOn < rhs.factorSource.common.addedOn
	}
}

extension FactorSourcesList.Row.Status {
	init(entity: EntitiesLinkedToFactorSource, problems: [SecurityProblem]) {
		let accounts = entity.accounts + entity.hiddenAccounts
		let personas = entity.personas

		// Determine row status
		self = if problems.hasProblem9(accounts: accounts, personas: personas) {
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
	}

	init?(integrity: FactorSourceIntegrity) {
		switch integrity {
		case let .device(deviceIntegrity):
			if !deviceIntegrity.isMnemonicPresentInSecureStorage {
				self = .lostFactorSource
			} else if !deviceIntegrity.isMnemonicMarkedAsBackedUp {
				self = .seedPhraseNotRecoverable
			} else if deviceIntegrity.isMnemonicMarkedAsBackedUp {
				self = .seedPhraseWrittenDown
			} else {
				return nil
			}
		default:
			return nil
		}
	}
}

extension FactorSourcesList.Row {
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

	enum Selectability: Sendable, Hashable {
		/// The row can be selected.
		case selectable

		/// The row cannot be selected because it was already selected for this context.
		/// It will show greyed out with the radio button already selected.
		case alreadySelected

		/// The row cannot be selected because it is in an invalid state (e.g. device factor source whose mnemonics are missing)
		/// It will show greyed out with the radio button unselected.
		case unselectable
	}
}

extension EntitiesLinkedToFactorSource {
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
