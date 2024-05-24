// MARK: - Troubleshooting

public struct Troubleshooting: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		var isLegacyImportEnabled = true

		@PresentationState
		public var destination: Destination.State?

		public init() {}
	}

	public enum ViewAction: Sendable, Equatable {
		case onFirstTask
		case accountScanButtonTapped
		case legacyImportButtonTapped
		case contactSupportButtonTapped
		case discordButtonTapped
		case factoryResetButtonTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case loadedIsLegacyImportEnabled(Bool)
	}

	public enum DelegateAction: Sendable, Equatable {
		case goToAccountList
		case didResetWallet
	}

	public struct Destination: DestinationReducer {
		public enum State: Sendable, Hashable {
			case accountRecovery(ManualAccountRecoveryCoordinator.State)
			case importOlympiaWallet(ImportOlympiaWalletCoordinator.State)
			case factoryReset(FactoryReset.State)
		}

		public enum Action: Sendable, Equatable {
			case accountRecovery(ManualAccountRecoveryCoordinator.Action)
			case importOlympiaWallet(ImportOlympiaWalletCoordinator.Action)
			case factoryReset(FactoryReset.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.accountRecovery, action: /Action.accountRecovery) {
				ManualAccountRecoveryCoordinator()
			}
			Scope(state: /State.importOlympiaWallet, action: /Action.importOlympiaWallet) {
				ImportOlympiaWalletCoordinator()
			}
			Scope(state: /State.factoryReset, action: /Action.factoryReset) {
				FactoryReset()
			}
		}
	}

	@Dependency(\.gatewaysClient) var gatewaysClient
	@Dependency(\.openURL) var openURL
	@Dependency(\.contactSupportClient) var contactSupport

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
			return loadIsLegacyImportEnabled()

		case .accountScanButtonTapped:
			state.destination = .accountRecovery(.init())
			return .none

		case .legacyImportButtonTapped:
			state.destination = .importOlympiaWallet(.init())
			return .none

		case .contactSupportButtonTapped:
			return .run { _ in
				await contactSupport.openEmail()
			}

		case .discordButtonTapped:
			guard let url = URL(string: "http://discord.gg/radixdlt") else {
				return .none
			}
			return .run { _ in
				await openURL(url)
			}

		case .factoryResetButtonTapped:
			state.destination = .factoryReset(.init())
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .loadedIsLegacyImportEnabled(isLegacyImportEnabled):
			state.isLegacyImportEnabled = isLegacyImportEnabled
			return .none
		}
	}

	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .accountRecovery(.delegate(.gotoAccountList)):
			return .send(.delegate(.goToAccountList))

		case let .importOlympiaWallet(.delegate(.finishedMigration(goToAccountList))):
			if goToAccountList {
				return .send(.delegate(.goToAccountList))
			} else {
				state.destination = nil
				return .none
			}

		case .factoryReset(.delegate(.didResetWallet)):
			return .send(.delegate(.didResetWallet))

		default:
			return .none
		}
	}

	private func loadIsLegacyImportEnabled() -> Effect<Action> {
		.run { send in
			await send(.internal(.loadedIsLegacyImportEnabled(
				gatewaysClient.getCurrentGateway().networkID == .mainnet
			)))
		}
	}
}
