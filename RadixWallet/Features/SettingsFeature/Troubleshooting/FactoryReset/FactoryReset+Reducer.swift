// MARK: - FactoryReset
public struct FactoryReset: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var isRecoverable = true

		@PresentationState
		public var destination: Destination.State?

		public init() {}
	}

	public enum ViewAction: Sendable, Equatable {
		case onFirstTask
		case resetWalletButtonTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case setIsRecoverable(Bool)
	}

	public enum DelegateAction: Sendable, Equatable {
		case didResetWallet
	}

	public struct Destination: DestinationReducer {
		@CasePathable
		public enum State: Sendable, Hashable {
			case confirmReset(AlertState<Action.ConfirmReset>)
		}

		@CasePathable
		public enum Action: Sendable, Hashable {
			case confirmReset(ConfirmReset)

			public enum ConfirmReset: Sendable, Hashable {
				case confirm
			}
		}

		public var body: some Reducer<State, Action> {
			EmptyReducer()
		}
	}

	@Dependency(\.cacheClient) var cacheClient
	@Dependency(\.radixConnectClient) var radixConnectClient
	@Dependency(\.userDefaults) var userDefaults
	@Dependency(\.securityCenterClient) var securityCenterClient

	public init() {}

	public var body: some ReducerOf<FactoryReset> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .onFirstTask:
			return isRecoverableEffect()
		case .resetWalletButtonTapped:
			state.destination = Destination.confirmResetState
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .setIsRecoverable(isRecoverable):
			state.isRecoverable = isRecoverable
			return .none
		}
	}

	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .confirmReset(.confirm):
			.run { send in
				cacheClient.removeAll()
				await radixConnectClient.disconnectAll()
				userDefaults.removeAll()
				await send(.delegate(.didResetWallet))
			}
		}
	}

	private func isRecoverableEffect() -> Effect<Action> {
		.run { send in
			for try await isRecoverable in await securityCenterClient.isRecoverable() {
				guard !Task.isCancelled else { return }
				await send(.internal(.setIsRecoverable(isRecoverable)))
			}
		}
	}
}

extension FactoryReset.Destination {
	static let confirmResetState: State = .confirmReset(.init(
		title: {
			TextState(L10n.FactoryReset.Dialog.title)
		},
		actions: {
			ButtonState(role: .destructive, action: .confirm) {
				TextState(L10n.Common.confirm)
			}
		},
		message: {
			TextState(L10n.FactoryReset.Dialog.message)
		}
	))
}
