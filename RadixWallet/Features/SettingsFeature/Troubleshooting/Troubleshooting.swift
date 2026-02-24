// MARK: - Troubleshooting
import FirebaseCrashlytics
import Sargon

// MARK: - Troubleshooting
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
		case rawManifestButtonTapped
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
			case rawManifestTransaction(RawManifestTransaction.State)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case accountRecovery(ManualAccountRecoveryCoordinator.Action)
			case importOlympiaWallet(ImportOlympiaWalletCoordinator.Action)
			case factoryReset(FactoryReset.Action)
			case rawManifestTransaction(RawManifestTransaction.Action)
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
			Scope(state: \.rawManifestTransaction, action: \.rawManifestTransaction) {
				RawManifestTransaction()
			}
		}
	}

	@Dependency(\.gatewaysClient) var gatewaysClient
	@Dependency(\.openURL) var openURL
	@Dependency(\.contactSupportClient) var contactSupport
	@Dependency(\.userDefaults) var userDefaults

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

		case .rawManifestButtonTapped:
			state.destination = .rawManifestTransaction(.init())
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

// MARK: - RawManifestTransaction
struct RawManifestTransaction: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		var manifest: String = ""
		var isSending: Bool = false

		var canSend: Bool {
			!manifest.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
		}
	}

	enum ViewAction: Sendable, Equatable {
		case manifestChanged(String)
		case sendTapped
	}

	enum InternalAction: Sendable, Equatable {
		case interactionCompleted
	}

	@Dependency(\.dappInteractionClient) var dappInteractionClient

	var body: some ReducerOf<Self> {
		Reduce(core)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .manifestChanged(manifest):
			state.manifest = manifest
			return .none

		case .sendTapped:
			guard state.canSend, !state.isSending else {
				return .none
			}
			state.isSending = true
			return .run { [manifest = state.manifest] send in
				let txManifest = TransactionManifest(instructions: .string(manifest))
				_ = await dappInteractionClient.addWalletInteraction(
					.transaction(.init(send: .init(transactionManifest: txManifest))),
					.accountTransfer
				)
				await send(.internal(.interactionCompleted))
			}
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case .interactionCompleted:
			state.isSending = false
			return .none
		}
	}
}
