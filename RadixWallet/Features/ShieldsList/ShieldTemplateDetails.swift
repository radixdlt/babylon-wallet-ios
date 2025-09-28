// MARK: - ShieldTemplateDetails
@Reducer
struct ShieldTemplateDetails: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		@Shared(.shieldBuilder) var shieldBuilder

		var structure: SecurityStructureOfFactorSources

		@Presents
		var destination: Destination.State? = nil
	}

	typealias Action = FeatureAction<Self>

	enum ViewAction: Sendable, Equatable {
		case editFactorsTapped
		case applyButtonTapped
		case renameButtonTapped
		case onFactorSourceTapped(FactorSource)
	}

	enum InternalAction: Sendable, Equatable {
		case secStructureUpdated(SecurityStructureOfFactorSources)
		case factorSourceIntegrityLoaded(FactorSourceIntegrity)
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case editShieldFactors(EditSecurityShieldCoordinator.State)
			case applyShield(ApplyShield.Coordinator.State)
			case rename(RenameLabel.State)
			case factorSourceDetails(FactorSourceDetail.State)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case editShieldFactors(EditSecurityShieldCoordinator.Action)
			case applyShield(ApplyShield.Coordinator.Action)
			case rename(RenameLabel.Action)
			case factorSourceDetails(FactorSourceDetail.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.editShieldFactors, action: \.editShieldFactors) {
				EditSecurityShieldCoordinator()
			}
			Scope(state: \.applyShield, action: \.applyShield) {
				ApplyShield.Coordinator()
			}
			Scope(state: \.rename, action: \.rename) {
				RenameLabel()
			}
			Scope(state: \.factorSourceDetails, action: \.factorSourceDetails) {
				FactorSourceDetail()
			}
		}
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.overlayWindowClient) var overlayWindowClient

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: \.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .editFactorsTapped:
			state.$shieldBuilder.withLock { [structure = state.structure] sharedValue in
				sharedValue = SecurityShieldBuilder.withSecurityStructureOfFactorSources(securityStructureOfFactorSources: structure)
			}
			state.destination = .editShieldFactors(.init())
			return .none

		case .applyButtonTapped:
			state.destination = .applyShield(.init(securityStructure: state.structure))
			return .none

		case .renameButtonTapped:
			state.destination = .rename(.init(kind: .shield(state.structure)))
			return .none

		case let .onFactorSourceTapped(factorSource):
			return .run { send in
				let integrity = try await SargonOS.shared.factorSourceIntegrity(factorSource: factorSource)
				await send(.internal(.factorSourceIntegrityLoaded(integrity)))
			} catch: { err, _ in
				errorQueue.schedule(err)
			}
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .secStructureUpdated(structure):
			// Reset state
			state.$shieldBuilder.withLock { shareValue in
				shareValue = SecurityShieldBuilder()
			}
			state.structure = structure
			return .none
		case let .factorSourceIntegrityLoaded(integrity):
			state.destination = .factorSourceDetails(.init(integrity: integrity))
			return .none
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .editShieldFactors(.delegate(.updated)):
			state.destination = nil
			return .run { [state] send in
				let secStructureOfFactorSourceIds = try state.shieldBuilder.build()
				try await SargonOS.shared.updateSecurityStructureOfFactorSourceIds(structureIds: secStructureOfFactorSourceIds)
				let updatedStructure = try SargonOS.shared.securityStructureOfFactorSourcesFromSecurityStructureOfFactorSourceIds(structureOfIds: secStructureOfFactorSourceIds)
				await send(.internal(.secStructureUpdated(updatedStructure)))
				overlayWindowClient.scheduleHUD(.succeeded)
			} catch: { err, _ in
				errorQueue.schedule(err)
			}
		case .editShieldFactors(.delegate(.cancelled)):
			state.destination = nil
			return .none
		case .applyShield(.delegate(.finished)):
			state.destination = nil
			return .none
		case .applyShield(.delegate(.skipped)):
			state.destination = nil
			return .none
		default:
			return .none
		}
	}
}
