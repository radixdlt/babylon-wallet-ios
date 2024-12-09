// MARK: - SecurityFactors

struct SecurityFactors: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		var securityProblems: [SecurityProblem] = []

		@PresentationState
		var destination: Destination.State?

		init() {}
	}

	enum ViewAction: Sendable, Equatable {
		case task
		case factorSourceRowTapped(FactorSourceKind)
	}

	enum InternalAction: Sendable, Equatable {
		case setSecurityProblems([SecurityProblem])
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case device(DeviceFactorSourcesList.State)
			case ledgerWallets(LedgerHardwareDevices.State)
			case todo
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case device(DeviceFactorSourcesList.Action)
			case ledgerWallets(LedgerHardwareDevices.Action)
			case todo(Never)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.device, action: \.device) {
				DeviceFactorSourcesList()
			}
			Scope(state: \.ledgerWallets, action: \.ledgerWallets) {
				LedgerHardwareDevices()
			}
		}
	}

	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.securityCenterClient) var securityCenterClient

	init() {}

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			return securityProblemsEffect()

		case let .factorSourceRowTapped(kind):
			switch kind {
			case .device:
				state.destination = .device(.init())
			case .ledgerHqHardwareWallet:
				state.destination = .ledgerWallets(.init(context: .settings))
			case .arculusCard, .password, .offDeviceMnemonic:
				state.destination = .todo
			case .trustedContact, .securityQuestions:
				fatalError("Unsupported Factor Source")
			}
			return .none
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .setSecurityProblems(problems):
			state.securityProblems = problems
			return .none
		}
	}

	private func securityProblemsEffect() -> Effect<Action> {
		.run { send in
			for try await problems in await securityCenterClient.problems(.securityFactors) {
				guard !Task.isCancelled else { return }
				await send(.internal(.setSecurityProblems(problems)))
			}
		}
	}
}
