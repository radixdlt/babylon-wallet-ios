// MARK: - SecurityFactors

public struct SecurityFactors: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var seedPhrasesCount: Int?
		public var ledgerWalletsCount: Int?
		public var securityProblems: [SecurityProblem] = []

		@PresentationState
		public var destination: Destination.State?

		public init() {}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case seedPhrasesButtonTapped
		case ledgerWalletsButtonTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case loadedSeedPhrasesCount(Int)
		case loadedLedgerWalletsCount(Int)
		case setSecurityProblems([SecurityProblem])
	}

	public struct Destination: DestinationReducer {
		@CasePathable
		public enum State: Sendable, Hashable {
			case seedPhrases(DisplayMnemonics.State)
			case ledgerWallets(LedgerHardwareDevices.State)
		}

		@CasePathable
		public enum Action: Sendable, Equatable {
			case seedPhrases(DisplayMnemonics.Action)
			case ledgerWallets(LedgerHardwareDevices.Action)
		}

		public var body: some ReducerOf<Self> {
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

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
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

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
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
