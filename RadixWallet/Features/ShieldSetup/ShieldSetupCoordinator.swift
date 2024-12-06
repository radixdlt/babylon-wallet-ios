// MARK: - ShieldSetupCoordinator
@Reducer
struct ShieldSetupCoordinator: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		var onboarding: ShieldSetupOnboarding.State = .init()
		var path: StackState<Path.State> = .init()
	}

	@Reducer(state: .hashable, action: .equatable)
	enum Path {
		case prepareFactors(PrepareFactorSources.Coordinator)
		case selectFactors(SelectFactorSources)
	}

	typealias Action = FeatureAction<Self>

	enum InternalAction: Sendable, Equatable {
		case prepareFactors
		case selectFactors
	}

	@CasePathable
	enum ChildAction: Sendable, Equatable {
		case onboarding(ShieldSetupOnboarding.Action)
		case path(StackActionOf<Path>)
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
		case .prepareFactors:
			state.path.append(.prepareFactors(.init(path: .intro)))
			return .none
		case .selectFactors:
			state.path.append(.selectFactors(.init()))
			return .none
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .onboarding(.delegate(.finished)):
			return onboardingFinishedEffect()
		case let .path(.element(id: _, action: .prepareFactors(.delegate(.push(path))))):
			state.path.append(.prepareFactors(.init(path: path)))
			return .none
		case .path(.element(id: _, action: .prepareFactors(.delegate(.finished)))):
			return .send(.internal(.selectFactors))
		default:
			return .none
		}
	}
}

private extension ShieldSetupCoordinator {
	func onboardingFinishedEffect() -> Effect<Action> {
		.run { send in
//			let status = try SargonOS.shared.securityShieldPrerequisitesStatus()
//			switch status {
//			case .hardwareRequired, .anyRequired:
//				await send(.internal(.prepareFactors))
//			case .sufficient:
			await send(.internal(.selectFactors))
//			}
		}
	}
}
