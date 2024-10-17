// MARK: - FactoryReset
struct FactoryReset: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		var isRecoverable = true

		@PresentationState
		var destination: Destination.State?

		init() {}
	}

	enum ViewAction: Sendable, Equatable {
		case onFirstTask
		case resetWalletButtonTapped
	}

	enum InternalAction: Sendable, Equatable {
		case setIsRecoverable(Bool)
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case confirmReset(AlertState<Action.ConfirmReset>)
		}

		@CasePathable
		enum Action: Sendable, Hashable {
			case confirmReset(ConfirmReset)

			enum ConfirmReset: Sendable, Hashable {
				case confirm
			}
		}

		var body: some Reducer<State, Action> {
			EmptyReducer()
		}
	}

	@Dependency(\.securityCenterClient) var securityCenterClient
	@Dependency(\.resetWalletClient) var resetWalletClient

	init() {}

	var body: some ReducerOf<FactoryReset> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .onFirstTask:
			return isRecoverableEffect()
		case .resetWalletButtonTapped:
			state.destination = Destination.confirmResetState
			return .none
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .setIsRecoverable(isRecoverable):
			state.isRecoverable = isRecoverable
			return .none
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .confirmReset(.confirm):
			.run { _ in
				await resetWalletClient.resetWallet()
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
