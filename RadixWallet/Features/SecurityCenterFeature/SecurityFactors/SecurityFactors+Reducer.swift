// MARK: - SecurityFactors

struct SecurityFactors: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		var seedPhrasesCount: Int?
		var ledgerWalletsCount: Int?
		var securityProblems: [SecurityProblem] = []

		@PresentationState
		var destination: Destination.State?

		init() {}
	}

	enum ViewAction: Sendable, Equatable {
		case task
		case seedPhrasesButtonTapped
		case ledgerWalletsButtonTapped
	}

	enum InternalAction: Sendable, Equatable {
		case loadedSeedPhrasesCount(Int)
		case loadedLedgerWalletsCount(Int)
		case setSecurityProblems([SecurityProblem])
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case seedPhrases(DisplayMnemonics.State)
			case ledgerWallets(LedgerHardwareDevices.State)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case seedPhrases(DisplayMnemonics.Action)
			case ledgerWallets(LedgerHardwareDevices.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.seedPhrases, action: \.seedPhrases) {
				DisplayMnemonics()
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
			return loadSeedPhrasesCount()
				.merge(with: loadLedgerWalletsCount())
				.merge(with: securityProblemsEffect())

		case .seedPhrasesButtonTapped:
			state.destination = .seedPhrases(.init())
			return .none

		case .ledgerWalletsButtonTapped:
			state.destination = .ledgerWallets(.init(context: .settings))
			return .none
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .loadedSeedPhrasesCount(count):
			state.seedPhrasesCount = count
			return .none

		case let .loadedLedgerWalletsCount(count):
			state.ledgerWalletsCount = count
			return .none

		case let .setSecurityProblems(problems):
			state.securityProblems = problems
			return .none
		}
	}

	private func loadSeedPhrasesCount() -> Effect<Action> {
		.run { send in
			try await send(.internal(.loadedSeedPhrasesCount(
				factorSourcesClient.getFactorSources(type: DeviceFactorSource.self).count
			)))
		}
	}

	private func loadLedgerWalletsCount() -> Effect<Action> {
		.run { send in
			try await send(.internal(.loadedLedgerWalletsCount(
				factorSourcesClient.getFactorSources(type: LedgerHardwareWalletFactorSource.self).count
			)))
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
