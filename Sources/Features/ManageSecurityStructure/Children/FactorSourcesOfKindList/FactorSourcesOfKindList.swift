import FactorSourcesClient
import FeaturePrelude
import Profile

// MARK: - DeleteExistingFactorSourceConfirmationDialogAction
public enum DeleteExistingFactorSourceConfirmationDialogAction: Sendable, Hashable {
	case deleteExistingFactorSource(FactorSourceID)
	case cancel
}

// MARK: - FactorSourcesOfKindList
public struct FactorSourcesOfKindList<FactorSourceOfKind: Sendable & Hashable>: Sendable, FeatureReducer where FactorSourceOfKind: FactorSourceProtocol {
	// MARK: - State

	public struct State: Sendable, Hashable {
		public enum Mode {
			case onlyPresentList
			case selection
		}

		public let mode: Mode

		public var factorSources: IdentifiedArrayOf<FactorSourceOfKind> = []
		public var idOfFactorSourceToFlagForDeletionUponSuccessfulCreationOfNew: FactorSourceID?

		public var selectedFactorSourceID: FactorSourceOfKind.ID?

		@PresentationState
		public var destination: Destinations.State? = nil

		public init(
			mode: Mode,
			selectedFactorSource: FactorSourceOfKind? = nil
		) {
			self.mode = mode
			if let selectedFactorSource {
				self.selectedFactorSourceID = selectedFactorSource.id
				self.factorSources = [selectedFactorSource]
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

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case addNewFactorSource(ManageSomeFactorSource<FactorSourceOfKind>.State)
			case existingFactorSourceWillBeDeletedConfirmationDialog(ConfirmationDialogState<DeleteExistingFactorSourceConfirmationDialogAction>)
		}

		public enum Action: Sendable, Equatable {
			case addNewFactorSource(ManageSomeFactorSource<FactorSourceOfKind>.Action)
			case existingFactorSourceWillBeDeletedConfirmationDialog(DeleteExistingFactorSourceConfirmationDialogAction)
		}

		public init() {}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.addNewFactorSource, action: /Action.addNewFactorSource) {
				ManageSomeFactorSource<FactorSourceOfKind>()
			}
		}
	}

	// MARK: - Reducer

	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.errorQueue) var errorQueue

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	var canOnlyHaveOneFactorSourceOfKind: Bool {
		switch FactorSourceOfKind.kind {
		case .ledgerHQHardwareWallet, .offDeviceMnemonic, .trustedContact: return false
		case .securityQuestions:
			return true
		case .device:
			// Well... it is complicated, we don't allow users to manually create more Babylon device
			// factor sources. But user can import as many legacy/olympia device factor source they want.
			return true
		}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .onFirstTask:
			return updateFactorSourcesEffect(state: &state)

		case let .selectedFactorSource(selectedID):
			state.selectedFactorSourceID = selectedID
			return .none

		case let .confirmedFactorSource(factorSource):
			return .send(.delegate(.choseFactorSource(factorSource)))

		case .addNewFactorSourceButtonTapped:
			if canOnlyHaveOneFactorSourceOfKind, let existing = state.factorSources.last {
				assert(state.factorSources.count == 1, "Expected to only have one factor source")
				assert(!existing.isFlaggedForDeletion)
				state.destination = .existingFactorSourceWillBeDeletedConfirmationDialog(.deletion(of: existing))
			} else {
				state.destination = .addNewFactorSource(.init())
			}
			return .none

		case .whatIsAFactorSourceButtonTapped:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
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

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
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
				return .fireAndForget {
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
				state.destination = .addNewFactorSource(.init())
				return .none
			}

		default:
			return .none
		}
	}

	private func updateFactorSourcesEffect(state: inout State) -> EffectTask<Action> {
		.task {
			let result = await TaskResult {
				let all = try await factorSourcesClient.getFactorSources(type: FactorSourceOfKind.self)
				return all.filter { !$0.isFlaggedForDeletion }
			}
			return .internal(.loadedFactorSources(result))
		}
	}
}

extension ConfirmationDialogState<DeleteExistingFactorSourceConfirmationDialogAction> {
	static func deletion(
		of factorSource: some FactorSourceProtocol
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
