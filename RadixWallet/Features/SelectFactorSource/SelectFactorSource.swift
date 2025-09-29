// MARK: - SelectFactorSource
@Reducer
struct SelectFactorSource: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		enum Context: Hashable {
			case createAccount
			case createPersona
			case accountRecovery(isOlympia: Bool)
		}

		let context: Context

		var rows: [FactorSourcesList.Row] = []
		var selectedFactorSourceId: FactorSourceID?
		var selectedFactorSource: FactorSourcesList.Row? {
			rows.first(where: { $0.id == selectedFactorSourceId })
		}

		var kinds: [FactorSourceKind] {
			switch context {
			case .createAccount, .createPersona, .accountRecovery(false):
				[.device, .ledgerHqHardwareWallet, .arculusCard, .offDeviceMnemonic]
			case .accountRecovery(true):
				[.device, .ledgerHqHardwareWallet]
			}
		}

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
		case messageTapped(FactorSourcesList.Row)
		case continueButtonTapped(FactorSourcesList.Row)
	}

	enum InternalAction: Equatable, Sendable {
		case setSecurityProblems([SecurityProblem])
		case setEntities([EntitiesLinkedToFactorSource])
		case hasAConnectorExtension(Bool)
	}

	enum DelegateAction: Equatable, Sendable {
		case selectedFactorSource(FactorSource, context: State.Context)
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Hashable, Sendable {
			case addSecurityFactor(AddFactorSource.Coordinator.State)
			case addNewP2PLink(NewConnection.State)
			case displayMnemonic(DisplayMnemonic.State)
			case enterMnemonic(ImportMnemonicForFactorSource.State)
		}

		@CasePathable
		enum Action: Equatable, Sendable {
			case addSecurityFactor(AddFactorSource.Coordinator.Action)
			case addNewP2PLink(NewConnection.Action)
			case displayMnemonic(DisplayMnemonic.Action)
			case enterMnemonic(ImportMnemonicForFactorSource.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.addSecurityFactor, action: \.addSecurityFactor) {
				AddFactorSource.Coordinator()
			}

			Scope(state: \.addNewP2PLink, action: \.addNewP2PLink) {
				NewConnection()
			}

			Scope(state: \.displayMnemonic, action: \.displayMnemonic) {
				DisplayMnemonic()
			}

			Scope(state: \.enterMnemonic, action: \.enterMnemonic) {
				ImportMnemonicForFactorSource()
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
			return entitiesEffect(state: state)
				.merge(with: checkP2PLinkEffect())

		case let .rowTapped(row):
			guard row?.selectability != .unselectable else {
				return .none
			}
			state.selectedFactorSourceId = row?.id
			return .none

		case let .messageTapped(row):
			switch row.status {
			case .seedPhraseWrittenDown, .notBackedUp:
				return .none

			case .seedPhraseNotRecoverable:
				return exportMnemonic(integrity: row.integrity) {
					state.destination = .displayMnemonic(.init(mnemonic: $0.mnemonicWithPassphrase.mnemonic, factorSourceID: $0.factorSourceID))
				}

			case .lostFactorSource:
				state.destination = .enterMnemonic(.init(
					deviceFactorSource: row.integrity.factorSource.asDevice!,
					profileToCheck: .current
				))
				return .none

			case .none:
				return .none
			}

		case let .continueButtonTapped(row):
			if row.integrity.factorSource.kind == .ledgerHqHardwareWallet, !state.hasAConnectorExtension {
				state.destination = .addNewP2PLink(.init(root: .ledgerConnectionIntro))
				return .none
			}
			return .send(.delegate(.selectedFactorSource(row.integrity.factorSource, context: state.context)))

		case .addSecurityFactorTapped:
			let context: AddFactorSource.Context = switch state.context {
			case .createAccount, .createPersona: .newFactorSource
			case let .accountRecovery(isOlympia): .recoverFactorSource(isOlympia: isOlympia)
			}

			state.destination = .addSecurityFactor(.init(
				mode: .toSelectFromKinds(state.kinds),
				context: context
			))
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
			state.entities = entities.filter { entity in
				switch state.context {
				case .createAccount, .createPersona, .accountRecovery(false):
					entity.integrity.factorSource.supportsBabylon
				case .accountRecovery(true):
					entity.integrity.factorSource.supportsOlympia
				}
			}
			setRows(state: &state)
			return .none

		case let .hasAConnectorExtension(hasCE):
			state.hasAConnectorExtension = hasCE
			return .none
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case let .addSecurityFactor(.delegate(.finished(fs))):
			state.destination = nil
			state.selectedFactorSourceId = fs.id
			return entitiesEffect(state: state)
		case .addNewP2PLink(.delegate(.newConnection)):
			state.destination = nil
			guard let selectedFactorSource = state.selectedFactorSource?.integrity.factorSource else {
				return .none
			}
			return .send(.delegate(.selectedFactorSource(selectedFactorSource, context: state.context)))
		case .displayMnemonic(.delegate(.backedUp)):
			state.destination = nil
			return entitiesEffect(state: state)
		case .enterMnemonic(.delegate(.imported)):
			state.destination = nil
			return entitiesEffect(state: state)
		case .enterMnemonic(.delegate):
			state.destination = nil
			return .none
		default:
			return .none
		}
	}

	func setRows(state: inout State) {
		guard let entities = state.entities else {
			return
		}
		state.rows = entities.map { entity in
			let status = FactorSourcesList.Row.Status(integrity: entity.integrity)
			return FactorSourcesList.Row(
				integrity: entity.integrity,
				linkedEntities: entity.linkedEntities,
				status: status,
				selectability: status == .lostFactorSource ? .unselectable : .selectable
			)
		}.sorted { lhs, rhs in
			let lhsFS: FactorSource = lhs.integrity.factorSource
			let rhsFS: FactorSource = rhs.integrity.factorSource

			if lhsFS.kind == rhsFS.kind {
				return lhsFS.lastUsedOn > rhsFS.lastUsedOn
			} else {
				return lhsFS.kind.selectOrder < rhsFS.kind.selectOrder
			}
		}
	}

	func entitiesEffect(state: State) -> Effect<Action> {
		.run { [kinds = state.kinds] send in
			let result = try await factorSourcesClient.entititesLinkedToFactorSourceKinds(Set(kinds))
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

private extension FactorSourceKind {
	var selectOrder: Int {
		switch self {
		case .device: 1
		case .ledgerHqHardwareWallet: 2
		case .arculusCard: 3
		case .offDeviceMnemonic: 4
		case .password: 5
		}
	}
}
