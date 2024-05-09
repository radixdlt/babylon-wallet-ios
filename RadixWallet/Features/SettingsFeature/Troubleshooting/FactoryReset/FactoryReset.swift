// MARK: - FactoryReset

public struct FactoryReset: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		@PresentationState
		public var destination: Destination.State?

		public init() {}
	}

	public enum ViewAction: Sendable, Equatable {
		case resetWalletButtonTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case resettedWallet
	}

	public struct Destination: DestinationReducer {
		static let confirmResetState: Self.State = .confirmReset(.init(
			title: {
				TextState("Confirm factory reset")
			},
			actions: {
				ButtonState(role: .destructive, action: .confirm) {
					TextState(L10n.Common.confirm)
				}
			},
			message: {
				TextState("Return wallet to factory settings? You cannot undo this.")
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
		case .resetWalletButtonTapped:
			state.destination = Destination.confirmResetState
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
}
