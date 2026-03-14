import ComposableArchitecture
import Sargon

// MARK: - SecurityCenter
struct SecurityCenter: FeatureReducer {
	struct State: Hashable {
		var isStokenet: Bool = false
		var problems: [SecurityProblem] = []
		var actionsRequired: Set<SecurityProblemKind> {
			Set(problems.map(\.kind))
		}

		@PresentationState
		var destination: Destination.State? = nil

		init() {}
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Hashable {
			case configurationBackup(ConfigurationBackup.State)
			case securityFactors(SecurityFactors.State)
			case mfaFactorInstance(MfaFactorInstance.State)
			case selectFactorSource(SelectFactorSource.State)
			case addressDetails(AddressDetails.State)
			case deviceFactorSources(FactorSourcesList.State)
			case importMnemonics(ImportMnemonicsFlowCoordinator.State)
			case securityShieldsSetup(ShieldSetupCoordinator.State)
			case securityShieldsList(ShieldsList.State)
			case applyShield(ApplyShield.Coordinator.State)
		}

		@CasePathable
		enum Action: Equatable {
			case configurationBackup(ConfigurationBackup.Action)
			case securityFactors(SecurityFactors.Action)
			case mfaFactorInstance(MfaFactorInstance.Action)
			case selectFactorSource(SelectFactorSource.Action)
			case addressDetails(AddressDetails.Action)
			case deviceFactorSources(FactorSourcesList.Action)
			case importMnemonics(ImportMnemonicsFlowCoordinator.Action)
			case securityShieldsSetup(ShieldSetupCoordinator.Action)
			case securityShieldsList(ShieldsList.Action)
			case applyShield(ApplyShield.Coordinator.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.configurationBackup, action: \.configurationBackup) {
				ConfigurationBackup()
			}
			Scope(state: \.securityFactors, action: \.securityFactors) {
				SecurityFactors()
			}
			Scope(state: \.mfaFactorInstance, action: \.mfaFactorInstance) {
				MfaFactorInstance()
			}
			Scope(state: \.selectFactorSource, action: \.selectFactorSource) {
				SelectFactorSource()
			}
			Scope(state: \.addressDetails, action: \.addressDetails) {
				AddressDetails()
			}
			Scope(state: \.deviceFactorSources, action: \.deviceFactorSources) {
				FactorSourcesList()
			}
			Scope(state: \.importMnemonics, action: \.importMnemonics) {
				ImportMnemonicsFlowCoordinator()
			}
			Scope(state: \.securityShieldsSetup, action: \.securityShieldsSetup) {
				ShieldSetupCoordinator()
			}
			Scope(state: \.securityShieldsList, action: \.securityShieldsList) {
				ShieldsList()
			}
			Scope(state: \.applyShield, action: \.applyShield) {
				ApplyShield.Coordinator()
			}
		}
	}

	enum ViewAction: Equatable {
		case task
		case problemTapped(SecurityProblem)
		case cardTapped(SecurityProblemKind)
		case mfaFactorInstanceTapped
	}

	enum InternalAction: Equatable {
		case setProblems([SecurityProblem])
		case setIsStokenet(Bool)
		case mfaSignatureResourceLoaded(NonFungibleGlobalId)
	}

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: \.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	@Dependency(\.securityCenterClient) var securityCenterClient
	@Dependency(\.gatewaysClient) var gatewaysClient
	@Dependency(\.errorQueue) var errorQueue

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			return securityProblemsEffect()
				.merge(with: .run { send in
					let isStokenet = await gatewaysClient.getCurrentGateway().network.id == .stokenet
					await send(.internal(.setIsStokenet(isStokenet)))
				})

		case let .problemTapped(problem):
			switch problem {
			case .problem3:
				state.destination = .deviceFactorSources(.init(kind: .device))

			case .problem5, .problem6, .problem7:
				state.destination = .configurationBackup(.init())

			case .problem9:
				state.destination = .importMnemonics(.init(profileToCheck: .current))
			}
			return .none

		case let .cardTapped(type):
			switch type {
			case .securityShields:
				let shields = (try? SargonOs.shared.securityStructuresOfFactorSourceIds()) ?? []
				if shields.isEmpty {
					state.destination = .securityShieldsSetup(.init())
				} else {
					state.destination = .securityShieldsList(.init())
				}
				return .none

			case .securityFactors:
				state.destination = .securityFactors(.init())
				return .none

			case .configurationBackup:
				state.destination = .configurationBackup(.init())
				return .none
			}

		case .mfaFactorInstanceTapped:
			state.destination = .mfaFactorInstance(.init())
			return .none
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .setProblems(problems):
			state.problems = problems
			return .none
		case let .setIsStokenet(isStokenet):
			state.isStokenet = isStokenet
			return .none
		case let .mfaSignatureResourceLoaded(globalId):
			state.destination = .addressDetails(.init(address: .nonFungibleGlobalID(globalId)))
			return .none
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .mfaFactorInstance(.delegate(.continueTapped)):
			state.destination = .selectFactorSource(.init(context: .mfaFactorInstance))
			return .none
		case let .selectFactorSource(.delegate(.selectedFactorSource(factorSource, _))):
			return .run { send in
				let mfaFactorInstance = try await SargonOs.shared.getNewMfaFactorInstance(factorSource: factorSource.asGeneral)
				let globalId = switch mfaFactorInstance.factorInstance.badge {
				case let .virtual(.hierarchicalDeterministic(key)):
					try key.nonFungibleGlobalId()
				}
				await send(.internal(.mfaSignatureResourceLoaded(globalId)))
			} catch: { err, _ in
				errorQueue.schedule(err)
			}
		case .importMnemonics(.delegate(.finishedEarly)),
		     .importMnemonics(.delegate(.finishedImportingMnemonics)):
			state.destination = nil
			return .none
		case let .securityShieldsSetup(.delegate(.finished(securityStructure))):
			state.destination = .applyShield(.init(securityStructure: securityStructure))
			return .none
		case .applyShield(.delegate(.skipped)):
			state.destination = .securityShieldsList(.init())
			return .none
		case .applyShield(.delegate(.finished)):
			state.destination = nil
			return .none
		default:
			return .none
		}
	}

	private func securityProblemsEffect() -> Effect<Action> {
		.run { send in
			for try await problems in await securityCenterClient.problems() {
				guard !Task.isCancelled else { return }
				await send(.internal(.setProblems(problems)))
			}
		}
	}
}

// MARK: - MfaFactorInstance
@Reducer
struct MfaFactorInstance {
	@ObservableState
	struct State: Hashable {
		struct ActiveUsage: Hashable {
			let signatureResource: NonFungibleGlobalId
			let accountAddresses: [AccountAddress]
		}

		var activeUsages: [ActiveUsage] = []
		var isLoadingCurrentUsage: Bool = false
	}

	enum Action: Equatable {
		case appeared
		case currentUsageLoaded([State.ActiveUsage])
		case continueTapped
		case delegate(DelegateAction)
	}

	enum DelegateAction: Equatable {
		case continueTapped
	}

	@Dependency(\.errorQueue) var errorQueue

	var body: some ReducerOf<Self> {
		Reduce { state, action in
			switch action {
			case .appeared:
				state.isLoadingCurrentUsage = true
				return .run { send in
					let used = try await SargonOs.shared.usedMfaSignatureResourcesWithAccountsCurrentNetwork()
					let usages = used.map { usedResource in
						State.ActiveUsage(
							signatureResource: usedResource.nonFungibleGlobalId,
							accountAddresses: usedResource.accountAddresses
						)
					}
					await send(.currentUsageLoaded(usages))
				} catch: { error, send in
					await send(.currentUsageLoaded([]))
					errorQueue.schedule(error)
				}

			case let .currentUsageLoaded(currentUsages):
				state.activeUsages = currentUsages
				state.isLoadingCurrentUsage = false
				return .none

			case .continueTapped:
				return .send(.delegate(.continueTapped))

			case .delegate:
				return .none
			}
		}
	}
}
