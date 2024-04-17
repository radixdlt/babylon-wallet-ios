// MARK: - SecurityFactors

public struct SecurityFactors: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		var seedPhrases: Int?
		var ledgerWallets: Int?

		@PresentationState
		public var destination: Destination.State?

		public init() {}
	}

	public enum ViewAction: Sendable, Equatable {
		case onFirstTask
		case seedPhrasesButtonTapped
		case ledgerWalletsButtonTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case loadedSeedPhrases(Int)
		case loadedLedgerWallets(Int)
	}

	public struct Destination: DestinationReducer {
		public enum State: Sendable, Hashable {
			case seedPhrases(DisplayMnemonics.State)
			case ledgerWallets(LedgerHardwareDevices.State)
		}

		public enum Action: Sendable, Equatable {
			case seedPhrases(DisplayMnemonics.Action)
			case ledgerWallets(LedgerHardwareDevices.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.seedPhrases, action: /Action.seedPhrases) {
				DisplayMnemonics()
			}
			Scope(state: /State.ledgerWallets, action: /Action.ledgerWallets) {
				LedgerHardwareDevices()
			}
		}
	}

	@Dependency(\.factorSourcesClient) var factorSourcesClient

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
		case .onFirstTask:
			return loadSeedPhrasesCount()
				.merge(with: loadLedgerWalletsCount())

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
		case let .loadedSeedPhrases(count):
			state.seedPhrases = count
			return .none

		case let .loadedLedgerWallets(count):
			state.ledgerWallets = count
			return .none
		}
	}

	private func loadSeedPhrasesCount() -> Effect<Action> {
		.run { send in
			try await send(.internal(.loadedSeedPhrases(
				factorSourcesClient.getFactorSources(type: DeviceFactorSource.self).count
			)))
		}
	}

	private func loadLedgerWalletsCount() -> Effect<Action> {
		.run { send in
			try await send(.internal(.loadedLedgerWallets(
				factorSourcesClient.getFactorSources(type: LedgerHardwareWalletFactorSource.self).count
			)))
		}
	}
}
