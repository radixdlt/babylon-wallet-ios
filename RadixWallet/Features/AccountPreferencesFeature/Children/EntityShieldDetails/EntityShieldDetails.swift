// MARK: - EntityShieldDetails
@Reducer
struct EntityShieldDetails: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		let entityAddress: AddressOfAccountOrPersona
		let accessControllerAddress: AccessControllerAddress

		var accessControllerStateDetails: AccessControllerStateDetails?

		@Shared(.shieldBuilder) var shieldBuilder
		var structure: SecurityStructureOfFactorSources?

		@Presents
		var destination: Destination.State? = nil

		var hasTimedRecovery: Bool {
			accessControllerStateDetails?.timedRecoveryState != nil
		}

		var timedRecoveryBannerState: AccountBannerView.TimedRecoveryBannerState? {
			guard let timedRecoveryState = accessControllerStateDetails?.timedRecoveryState
			else {
				return nil
			}

			// Check if provisional state exists
			let hasProvisionalState = (try? SargonOs.shared.provisionalSecurityStructureOfFactorSourcesFromAddressOfAccountOrPersona(
				addressOfAccountOrPersona: entityAddress
			)) != nil

			if hasProvisionalState {
				// Known recovery - compute countdown
				if let timestamp = TimeInterval(timedRecoveryState.allowTimedRecoveryAfterUnixTimestampSeconds) {
					let confirmationDate = Date(timeIntervalSince1970: timestamp)
					let remaining = confirmationDate.timeIntervalSince(Date.now)

					if remaining > 0 {
						// Format countdown
						let days = Int(remaining) / 86400
						let hours = (Int(remaining) % 86400) / 3600

						let countdown = if days > 0 {
							"\(days)d"
						} else if hours > 0 {
							"\(hours)h"
						} else {
							"<1h"
						}
						return .inProgress(countdown: countdown)
					} else {
						// Ready to confirm
						return .inProgress(countdown: nil)
					}
				} else {
					return .inProgress(countdown: nil)
				}
			} else {
				// Unknown recovery
				return .unknown
			}
		}
	}

	typealias Action = FeatureAction<Self>

	enum ViewAction: Sendable, Equatable {
		case task
		case editFactorsTapped
		case onFactorSourceTapped(FactorSource)
		case timedRecoveryBannerTapped
	}

	enum InternalAction: Sendable, Equatable {
		case secStructureUpdated(SecurityStructureOfFactorSources)
		case factorSourceIntegrityLoaded(FactorSourceIntegrity)
		case accessControllerStateDetailsUpdated(AccessControllerStateDetails?)
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case editShieldFactors(EditSecurityShieldCoordinator.State)
			case factorSourceDetails(FactorSourceDetail.State)
			case applyShield(ApplyShield.Coordinator.State)
			case handleTimedRecovery(HandleAccessControllerTimedRecovery.State)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case editShieldFactors(EditSecurityShieldCoordinator.Action)
			case factorSourceDetails(FactorSourceDetail.Action)
			case applyShield(ApplyShield.Coordinator.Action)
			case handleTimedRecovery(HandleAccessControllerTimedRecovery.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.editShieldFactors, action: \.editShieldFactors) {
				EditSecurityShieldCoordinator()
			}
			Scope(state: \.factorSourceDetails, action: \.factorSourceDetails) {
				FactorSourceDetail()
			}
			Scope(state: \.applyShield, action: \.applyShield) {
				ApplyShield.Coordinator()
			}
			Scope(state: \.handleTimedRecovery, action: \.handleTimedRecovery) {
				HandleAccessControllerTimedRecovery()
			}
		}
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.overlayWindowClient) var overlayWindowClient
	@Dependency(\.accessControllerClient) var accessControllerClient

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
			do {
				state.structure = try SargonOS.shared.securityStructureOfFactorSourcesFromAddressOfAccountOrPersona(addressOfAccountOrPersona: state.entityAddress)
			} catch {
				errorQueue.schedule(error)
			}

			// Subscribe to access controller state updates if entity is securified
			return .run { [acAddress = state.accessControllerAddress] send in
				for try await acDetails in await accessControllerClient.accessControllerUpdates(acAddress) {
					await send(.internal(.accessControllerStateDetailsUpdated(acDetails)))
				}
			}
		case .editFactorsTapped:
			guard let structure = state.structure else { return .none }
			state.$shieldBuilder.withLock { [structure] sharedValue in
				sharedValue = SecurityShieldBuilder.withSecurityStructureOfFactorSources(securityStructureOfFactorSources: structure)
			}
			state.destination = .editShieldFactors(.init())
			return .none
		case let .onFactorSourceTapped(factorSource):
			return .run { send in
				let integrity = try await SargonOS.shared.factorSourceIntegrity(factorSource: factorSource)
				await send(.internal(.factorSourceIntegrityLoaded(integrity)))
			} catch: { err, _ in
				errorQueue.schedule(err)
			}
		case .timedRecoveryBannerTapped:
			guard let acDetails = state.accessControllerStateDetails else {
				return .none
			}
			do {
				state.destination = try .handleTimedRecovery(
					.init(acDetails: acDetails)
				)
			} catch {
				errorQueue.schedule(error)
			}
			return .none
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
		case let .accessControllerStateDetailsUpdated(acDetails):
			state.accessControllerStateDetails = acDetails
			return .none
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .editShieldFactors(.delegate(.updated)):
			do {
				let secStructureOfFactorSourceIds = try state.shieldBuilder.build()
				let securityStructure = try SargonOs.shared.securityStructureOfFactorSourcesFromSecurityStructureOfFactorSourceIds(structureOfIds: secStructureOfFactorSourceIds)
				state.destination = .applyShield(.init(securityStructure: securityStructure, entityAddress: state.entityAddress, root: .completion))
			} catch {
				errorQueue.schedule(error)
			}
			return .none
		case .editShieldFactors(.delegate(.cancelled)):
			state.destination = nil
			return .none
		case .applyShield(.delegate(.finished)):
			state.destination = nil
			return .none
		default:
			return .none
		}
	}
}
