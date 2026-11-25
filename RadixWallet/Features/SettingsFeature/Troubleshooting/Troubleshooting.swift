// MARK: - Troubleshooting
import FirebaseCrashlytics
import Sargon

// MARK: - Troubleshooting
struct Troubleshooting: FeatureReducer {
	struct State: Hashable {
		var isLegacyImportEnabled = true
		var shareCrashReportsIsEnabled = false

		@PresentationState
		var destination: Destination.State?

		init() {}
	}

	enum ViewAction: Equatable {
		case onFirstTask
		case accountScanButtonTapped
		case legacyImportButtonTapped
		case rawManifestButtonTapped
		case contactSupportButtonTapped
		case discordButtonTapped
		case factoryResetButtonTapped
		case crashReportingToggled(Bool)
	}

	enum InternalAction: Equatable {
		case loadedIsLegacyImportEnabled(Bool)
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Hashable {
			case accountRecovery(ManualAccountRecoveryCoordinator.State)
			case importOlympiaWallet(ImportOlympiaWalletCoordinator.State)
			case factoryReset(FactoryReset.State)
			case rawManifestTransaction(RawManifestTransaction.State)
		}

		@CasePathable
		enum Action: Equatable {
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
				await contactSupport.openSupport()
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
struct RawManifestTransaction: FeatureReducer {
	struct State: Hashable {
		enum Mode: String, CaseIterable, Hashable {
			case transaction = "Transaction"
			/// DEBUG tool: sends the manifest as a dApp-style pre-authorization (subintent) request.
			case preAuthorization = "Pre-authorization"
		}

		var mode: Mode = .transaction
		var manifest: String = ""
		var isSending: Bool = false
		/// Debug summary of the last signed subintent returned by the pre-authorization flow.
		var preAuthorizationResult: String?

		var canSend: Bool {
			!manifest.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
		}
	}

	enum ViewAction: Equatable {
		case manifestChanged(String)
		case modeChanged(State.Mode)
		case sendTapped
	}

	enum InternalAction: Equatable {
		case interactionCompleted
		case preAuthorizationSigned(String)
	}

	@Dependency(\.dappInteractionClient) var dappInteractionClient
	@Dependency(\.gatewaysClient) var gatewaysClient
	@Dependency(\.errorQueue) var errorQueue

	var body: some ReducerOf<Self> {
		Reduce(core)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .manifestChanged(manifest):
			state.manifest = manifest
			return .none

		case let .modeChanged(mode):
			state.mode = mode
			state.preAuthorizationResult = nil
			return .none

		case .sendTapped:
			guard state.canSend, !state.isSending else {
				return .none
			}

			state.isSending = true
			state.preAuthorizationResult = nil
			switch state.mode {
			case .transaction:
				return submitTransaction(state.manifest)
			case .preAuthorization:
				return submitPreAuthorization(state.manifest)
			}
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case .interactionCompleted:
			state.isSending = false
			return .none

		case let .preAuthorizationSigned(summary):
			state.preAuthorizationResult = summary
			return .none
		}
	}

	private func submitTransaction(_ manifestString: String) -> Effect<Action> {
		.run { send in
			do {
				let networkID = await gatewaysClient.getCurrentGateway().networkID
				let manifest = try TransactionManifest(
					instructionsString: manifestString,
					networkID: networkID
				)

				let result = await dappInteractionClient.addWalletInteraction(
					.transaction(.init(send: .init(transactionManifest: manifest))),
					.rawManifestTransaction
				)

				switch result.p2pResponse {
				case let .dapp(.success(success)):
					if case .transaction = success.items {
						await send(.internal(.interactionCompleted))
						return
					}
					assertionFailure("Not a transaction response for raw manifest")

				case .dapp(.failure):
					break
				}
			} catch {
				errorQueue.schedule(error)
			}

			await send(.internal(.interactionCompleted))
		}
	}

	private func submitPreAuthorization(_ manifestString: String) -> Effect<Action> {
		.run { send in
			let request = DappToWalletInteractionSubintentRequestItem(
				version: 1,
				unvalidatedManifest: .init(subintentManifestString: manifestString, blobs: Blobs([])),
				message: "Debug pre-authorization",
				expiration: .afterDelay(.init(expireAfterSeconds: 600)),
				header: nil
			)

			let result = await dappInteractionClient.addWalletInteraction(
				.preAuthorization(.init(request: request)),
				.rawManifestTransaction
			)

			switch result.p2pResponse {
			case let .dapp(.success(success)):
				if case let .preAuthorization(preAuthorization) = success.items {
					let signedSubintent = preAuthorization.response.signedSubintent
					let summary = """
					Subintent hash: \(signedSubintent.subintent.hash().formatted(.raw))
					Signatures: \(signedSubintent.subintentSignatures.signatures.count)

					\(signedSubintent.subintent.manifest.manifestString)
					"""
					loggerGlobal.notice("[DebugPreAuthorization] Signed subintent\n\(summary)")
					await send(.internal(.preAuthorizationSigned(summary)))
				} else {
					assertionFailure("Not a pre-authorization response for raw subintent manifest")
				}

			case let .dapp(.failure(failure)):
				loggerGlobal.notice("[DebugPreAuthorization] Failed: \(failure.error) \(failure.message ?? "")")
			}

			await send(.internal(.interactionCompleted))
		}
	}
}
