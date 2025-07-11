// MARK: - Troubleshooting
import FirebaseCrashlytics

struct Troubleshooting: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		var isLegacyImportEnabled = true
		var shareCrashReportsIsEnabled = false

		@PresentationState
		var destination: Destination.State?

		init() {}
	}

	enum ViewAction: Sendable, Equatable {
		case onFirstTask
		case accountScanButtonTapped
		case legacyImportButtonTapped
		case contactSupportButtonTapped
		case discordButtonTapped
		case factoryResetButtonTapped
		case crashReportingToggled(Bool)
	}

	enum InternalAction: Sendable, Equatable {
		case loadedIsLegacyImportEnabled(Bool)
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case accountRecovery(ManualAccountRecoveryCoordinator.State)
			case importOlympiaWallet(ImportOlympiaWalletCoordinator.State)
			case factoryReset(FactoryReset.State)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case accountRecovery(ManualAccountRecoveryCoordinator.Action)
			case importOlympiaWallet(ImportOlympiaWalletCoordinator.Action)
			case factoryReset(FactoryReset.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.accountRecovery, action: \.accountRecovery) {
				ManualAccountRecoveryCoordinator()
			}
			Scope(state: \.importOlympiaWallet, action: \.importOlympiaWallet) {
				ImportOlympiaWalletCoordinator()
			}
			Scope(state: \.factoryReset, action: \.factoryReset) {
				FactoryReset()
			}
		}
	}

	@Dependency(\.gatewaysClient) var gatewaysClient
	@Dependency(\.openURL) var openURL
	@Dependency(\.contactSupportClient) var contactSupport
	@Dependency(\.userDefaults) var userDefaults

	init() {}

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: \.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .onFirstTask:
			state.shareCrashReportsIsEnabled = userDefaults.shareCrashReportsIsEnabled
			return loadIsLegacyImportEnabled()

		case .accountScanButtonTapped:
			state.destination = .accountRecovery(.init())
			return .none

		case .legacyImportButtonTapped:
			state.destination = .importOlympiaWallet(.init())
			return .none

		case .contactSupportButtonTapped:
			return .run { _ in
				await contactSupport.openEmail(nil)
			}

		case .discordButtonTapped:
			guard let url = URL(string: "https://go.radixdlt.com/Discord") else {
				return .none
			}
			return .run { _ in
				await openURL(url)
			}

		case .factoryResetButtonTapped:
			state.destination = .factoryReset(.init())
			return .none

		case let .crashReportingToggled(isEnabled):
			userDefaults.setShareCrashReportsIsEnabled(isEnabled)
			Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(userDefaults.shareCrashReportsIsEnabled)
			state.shareCrashReportsIsEnabled = isEnabled
			return .none
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .loadedIsLegacyImportEnabled(isLegacyImportEnabled):
			state.isLegacyImportEnabled = isLegacyImportEnabled
			return .none
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .accountRecovery(.delegate(.completed)):
			state.destination = nil
			return .none

		case .importOlympiaWallet(.delegate(.finishedMigration)):
			state.destination = nil
			return .none

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
