// MARK: - FactoryReset

public struct FactoryReset: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		var isRecoverable = true

		@PresentationState
		public var destination: Destination.State?

		public init() {}
	}

	public enum ViewAction: Sendable, Equatable {
		case onFirstTask
		case resetWalletButtonTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case loadedIsRecoverable(Bool)
	}

	public enum DelegateAction: Sendable, Equatable {
		case resettedWallet
	}

	public struct Destination: DestinationReducer {
		static let confirmResetState: Self.State = .confirmReset(.init(
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

		public enum State: Sendable, Hashable {
			case confirmReset(AlertState<Action.ConfirmReset>)
		}

		public enum Action: Sendable, Hashable {
			case confirmReset(ConfirmReset)

			public enum ConfirmReset: Sendable, Hashable {
				case confirm
			}
		}

		public var body: some Reducer<State, Action> {
			Scope(state: /State.confirmReset, action: /Action.confirmReset) {
				EmptyReducer()
			}
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
			return loadIsRecoverable()
		case .resetWalletButtonTapped:
			state.destination = Destination.confirmResetState
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .loadedIsRecoverable(isRecoverable):
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
				await send(.delegate(.resettedWallet))
			}
		}
	}

	private func loadIsRecoverable() -> Effect<Action> {
		.run { send in
			for try await problems in await securityCenterClient.problems() {
				guard !Task.isCancelled else { return }
				let isRecoverable = !problems.contains(.problem5) && !problems.contains(.problem6) && !problems.contains(.problem7)
				await send(.internal(.loadedIsRecoverable(isRecoverable)))
			}
		}
	}
}
