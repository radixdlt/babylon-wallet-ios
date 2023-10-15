// MARK: - DeleteExistingFactorSourceConfirmationDialogAction
public enum DeleteExistingFactorSourceConfirmationDialogAction: Sendable, Hashable {
	case deleteExistingFactorSource(FactorSourceID)
	case cancel
}

// MARK: - FactorSourcesOfKindList
public struct FactorSourcesOfKindList<FactorSourceOfKind: Sendable & Hashable>: Sendable, FeatureReducer where FactorSourceOfKind: BaseFactorSourceProtocol {
	// MARK: - State

	public struct State: Sendable, Hashable {
		public enum Mode {
			case onlyPresentList
			case selection
		}

		public let kind: FactorSourceKind
		public let mode: Mode

		public var factorSources: IdentifiedArrayOf<FactorSourceOfKind> = []
		public var idOfFactorSourceToFlagForDeletionUponSuccessfulCreationOfNew: FactorSourceID?

		public let canAddNew: Bool

		public var selectedFactorSourceID: FactorSourceOfKind.ID?

		@PresentationState
		public var destination: Destinations.State? = nil

		public init(
			kind: FactorSourceKind,
			mode: Mode,
			selectedFactorSource: FactorSourceOfKind? = nil
		) {
			if let specificType = FactorSourceOfKind.self as? any FactorSourceProtocol.Type {
				precondition(specificType.kind == kind)
			}

			self.kind = kind
			self.mode = mode
			if let selectedFactorSource {
				self.selectedFactorSourceID = selectedFactorSource.id
				self.factorSources = [selectedFactorSource]
			}

			switch kind {
			case .device:
				self.canAddNew = false
			case .ledgerHQHardwareWallet, .offDeviceMnemonic, .securityQuestions, .trustedContact:
				self.canAddNew = true
			}
		}

		public var canOnlyHaveOneFactorSourceOfKind: Bool {
			switch kind {
			case .ledgerHQHardwareWallet, .offDeviceMnemonic, .trustedContact: return false
			case .securityQuestions:
				return true
			case .device:
				// Well... it is complicated, we don't allow users to manually create more Babylon device
				// factor sources. But user can import as many legacy/olympia device factor source they want.
				return true
			}
		}
	}

	// MARK: - Action

	public enum ViewAction: Sendable, Equatable {
		case onFirstTask
		case selectedFactorSource(id: FactorSourceOfKind.ID?)
		case addNewFactorSourceButtonTapped
		case confirmedFactorSource(FactorSourceOfKind)
		case whatIsAFactorSourceButtonTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case loadedFactorSources(TaskResult<IdentifiedArrayOf<FactorSourceOfKind>>)
	}

	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationAction<Destinations.Action>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case choseFactorSource(FactorSourceOfKind)
	}

	// MARK: - Destination

	public struct Destinations: Sendable, Reducer {
		public enum State: Sendable, Hashable {
			case addNewFactorSource(ManageSomeFactorSource<FactorSourceOfKind>.State)
			case existingFactorSourceWillBeDeletedConfirmationDialog(ConfirmationDialogState<DeleteExistingFactorSourceConfirmationDialogAction>)
		}

		public enum Action: Sendable, Equatable {
			case addNewFactorSource(ManageSomeFactorSource<FactorSourceOfKind>.Action)
			case existingFactorSourceWillBeDeletedConfirmationDialog(DeleteExistingFactorSourceConfirmationDialogAction)
		}

		public init() {}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.addNewFactorSource, action: /Action.addNewFactorSource) {
				ManageSomeFactorSource<FactorSourceOfKind>()
			}
		}
	}

	// MARK: - Reducer

	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.errorQueue) var errorQueue

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .onFirstTask:
			return updateFactorSourcesEffect(state: &state)

		case let .selectedFactorSource(selectedID):
			state.selectedFactorSourceID = selectedID
			return .none

		case let .confirmedFactorSource(factorSource):
			return .send(.delegate(.choseFactorSource(factorSource)))

		case .addNewFactorSourceButtonTapped:
			assert(state.canAddNew)

			if
				state.canOnlyHaveOneFactorSourceOfKind,
				let existing = state.factorSources.last
			{
				state.destination = .existingFactorSourceWillBeDeletedConfirmationDialog(.deletion(of: existing))
			} else {
				state.destination = .addNewFactorSource(.init(kind: state.kind))
			}
			return .none

		case .whatIsAFactorSourceButtonTapped:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .loadedFactorSources(.success(loadedFactors)):
			if let existing = state.factorSources.first {
				if !loadedFactors.contains(where: { $0.id == existing.id }) {
					assertionFailure("BAD loaded factor sources from profile does not contain pre-selected factor source.")
				}
			}
			state.factorSources = loadedFactors
			return .none
		case let .loadedFactorSources(.failure(error)):
			errorQueue.schedule(error)
			loggerGlobal.error("Failed to load factor sources from profile: \(error)")
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .destination(.presented(.addNewFactorSource(.delegate(newFactorSourceAction)))):
			switch newFactorSourceAction {
			case let .done(.success(factorSource)):
				state.destination = nil
				state.factorSources.append(factorSource)
				state.selectedFactorSourceID = factorSource.id
				guard let idOfFactorSourceToFlagForDeletionUponSuccessfulCreationOfNew = state.idOfFactorSourceToFlagForDeletionUponSuccessfulCreationOfNew else {
					return .none
				}
				state.idOfFactorSourceToFlagForDeletionUponSuccessfulCreationOfNew = nil
				state.factorSources.removeAll(where: { $0.id.embed() == idOfFactorSourceToFlagForDeletionUponSuccessfulCreationOfNew })
				return .run { _ in
					try await factorSourcesClient.flagFactorSourceForDeletion(
						idOfFactorSourceToFlagForDeletionUponSuccessfulCreationOfNew
					)
				}

			case let .done(.failure(error)):
				state.destination = nil
				return .none
			}

		case let .destination(.presented(.existingFactorSourceWillBeDeletedConfirmationDialog(confirmationAction))):
			switch confirmationAction {
			case .cancel:
				state.destination = nil
				return .none
			case let .deleteExistingFactorSource(id):
				state.idOfFactorSourceToFlagForDeletionUponSuccessfulCreationOfNew = id
				state.destination = .addNewFactorSource(.init(kind: state.kind))
				return .none
			}

		default:
			return .none
		}
	}

	private func updateFactorSourcesEffect(state: inout State) -> Effect<Action> {
		.run { [selectedID = state.selectedFactorSourceID, kind = state.kind] send in
			let result = await TaskResult {
				let all = try await factorSourcesClient.getFactorSources(matching: {
					$0.kind == kind
				})
				let filtered = all.filter { factorSource in
					if factorSource.id == selectedID?.embed() {
						return true
					}
					return !factorSource.isFlaggedForDeletion
				}
				let filteredType = filtered.map {
					guard let specificType = FactorSourceOfKind.self as? any FactorSourceProtocol.Type else {
						return $0 as! FactorSourceOfKind
					}
					return specificType.extract(from: $0) as! FactorSourceOfKind
				}
				return IdentifiedArrayOf<FactorSourceOfKind>.init(uncheckedUniqueElements: filteredType)
			}
			await send(.internal(.loadedFactorSources(result)))
		}
	}
}

extension ConfirmationDialogState<DeleteExistingFactorSourceConfirmationDialogAction> {
	static func deletion(
		of factorSource: some BaseFactorSourceProtocol
	) -> ConfirmationDialogState {
		.init(
			// FIXME: strings
			title: { TextState("Can only have one") },
			actions: {
				ButtonState(role: .destructive, action: .deleteExistingFactorSource(factorSource.id.embed())) {
					// FIXME: strings
					TextState("Replace existing with new")
				}
				ButtonState(role: .cancel, action: .cancel) {
					// FIXME: strings
					TextState("Keep existing")
				}
			},
			message: {
				// FIXME: strings
				TextState("You can only have one \(factorSource.kind.rawValue), the new you create will replace the old one.")
			}
		)
	}
}
