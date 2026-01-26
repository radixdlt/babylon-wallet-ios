// MARK: - ShieldSetupCoordinator
@Reducer
struct ShieldSetupCoordinator: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		@Shared(.shieldBuilder) var shieldBuilder

		var onboarding: ShieldSetupOnboarding.State = .init()
		var path: StackState<Path.State> = .init()
	}

	@Reducer
	enum Path {
		case addShieldBuilderSeedingFactors(AddShieldBuilderSeedingFactors.Coordinator)
		case pickShieldBuilderSeedingFactors(PickShieldBuilderSeedingFactorsCoordinator)
		case rolesSetup(RolesSetupCoordinator)
		case nameShield(NameShield)
	}

	typealias Action = FeatureAction<Self>

	enum InternalAction: Sendable, Equatable {
		case addShieldBuilderSeedingFactors
		case pickShieldBuilderSeedingFactors
	}

	@CasePathable
	enum ChildAction: Sendable, Equatable {
		case onboarding(ShieldSetupOnboarding.Action)
		case path(StackActionOf<Path>)
	}

	enum DelegateAction: Equatable, Sendable {
		case finished(SecurityStructureOfFactorSources)
	}

	var body: some ReducerOf<Self> {
		Scope(state: \.onboarding, action: \.child.onboarding) {
			ShieldSetupOnboarding()
		}
		Reduce(core)
			.forEach(\.path, action: \.child.path)
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case .addShieldBuilderSeedingFactors:
			state.path.append(.addShieldBuilderSeedingFactors(.init(path: .intro)))
			return .none
		case .pickShieldBuilderSeedingFactors:
			state.path.append(.pickShieldBuilderSeedingFactors(.init(path: .pickShieldBuilderSeedingFactors(.init()))))
			return .none
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .onboarding(.delegate(.finished)):
			return onboardingFinishedEffect()
		case let .path(.element(id: _, action: .addShieldBuilderSeedingFactors(.delegate(.push(path))))):
			state.path.append(.addShieldBuilderSeedingFactors(.init(path: path)))
			return .none
		case let .path(.element(id: _, action: .addShieldBuilderSeedingFactors(.delegate(.finished(shouldSkipAutomaticShield))))):
			if shouldSkipAutomaticShield {
				state.$shieldBuilder.initialize()
				state.path.append(.rolesSetup(.init()))
				return .none
			} else {
				return .send(.internal(.pickShieldBuilderSeedingFactors))
			}
		case .path(.element(id: _, action: .pickShieldBuilderSeedingFactors(.delegate(.finished)))):
			state.path.append(.rolesSetup(.init()))
			return .none
		case let .path(.element(id: _, action: .rolesSetup(.delegate(.push(path))))):
			state.path.append(.rolesSetup(.init(path: path)))
			return .none
		case .path(.element(id: _, action: .rolesSetup(.delegate(.finished)))):
			state.path.append(.nameShield(.init()))
			return .none
		case let .path(.element(id: _, action: .nameShield(.delegate(.finished(securityStructure))))):
			return .send(.delegate(.finished(securityStructure)))
		default:
			return .none
		}
	}
}

// MARK: - ShieldSetupCoordinator.Path.State + Hashable
extension ShieldSetupCoordinator.Path.State: Hashable {}

// MARK: - ShieldSetupCoordinator.Path.Action + Equatable
extension ShieldSetupCoordinator.Path.Action: Equatable {}

private extension ShieldSetupCoordinator {
	func onboardingFinishedEffect() -> Effect<Action> {
		.run { send in
			let status = try SargonOS.shared.securityShieldPrerequisitesStatus()
			switch status {
			case .hardwareRequired, .anyRequired:
				await send(.internal(.addShieldBuilderSeedingFactors))
			case .sufficient:
				await send(.internal(.pickShieldBuilderSeedingFactors))
			}
		}
	}
}
