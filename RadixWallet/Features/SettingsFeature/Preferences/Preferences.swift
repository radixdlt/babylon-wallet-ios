// MARK: - Preferences

struct Preferences: Sendable, FeatureReducer {
	@Environment(\.colorScheme) var colorScheme
	struct State: Sendable, Hashable {
		var appPreferences: AppPreferences?
		var exportLogsUrl: URL?

		@PresentationState
		var destination: Destination.State?

		init() {}
	}

	enum ViewAction: Sendable, Equatable {
		case appeared
		case depositGuaranteesButtonTapped
		case hiddenEntitiesButtonTapped
		case hiddenAssetsButtonTapped
		case themeSelectionButtonTapped
		case gatewaysButtonTapped
		case developerModeToogled(Bool)
		case advancedLockToogled(Bool)
		case exportLogsButtonTapped
		case exportLogsDismissed
	}

	enum InternalAction: Sendable, Equatable {
		case loadedAppPreferences(AppPreferences)
		case advancedLockToggleResult(authResult: TaskResult<Bool>, isEnabled: Bool)
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case depositGuarantees(DefaultDepositGuarantees.State)
			case hiddenEntities(HiddenEntities.State)
			case hiddenAssets(HiddenAssets.State)
			case themeSelection(ThemeSelection.State)
			case gateways(GatewaySettings.State)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case depositGuarantees(DefaultDepositGuarantees.Action)
			case hiddenEntities(HiddenEntities.Action)
			case hiddenAssets(HiddenAssets.Action)
			case themeSelection(ThemeSelection.Action)
			case gateways(GatewaySettings.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.depositGuarantees, action: \.depositGuarantees) {
				DefaultDepositGuarantees()
			}
			Scope(state: \.hiddenEntities, action: \.hiddenEntities) {
				HiddenEntities()
			}
			Scope(state: \.hiddenAssets, action: \.hiddenAssets) {
				HiddenAssets()
			}
			Scope(state: \.themeSelection, action: \.themeSelection) {
				ThemeSelection()
			}
			Scope(state: \.gateways, action: \.gateways) {
				GatewaySettings()
			}
		}
	}

	@Dependency(\.appPreferencesClient) var appPreferencesClient
	@Dependency(\.localAuthenticationClient) var localAuthenticationClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.userDefaults) var userDefaults

	init() {}

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			return .run { send in
				let appPreferences = await appPreferencesClient.getPreferences()
				await send(.internal(.loadedAppPreferences(appPreferences)))
			}

		case .depositGuaranteesButtonTapped:
			let depositGuarantee = state.appPreferences?.transaction.defaultDepositGuarantee ?? 1
			state.destination = .depositGuarantees(.init(depositGuarantee: depositGuarantee))
			return .none

		case .hiddenEntitiesButtonTapped:
			state.destination = .hiddenEntities(.init())
			return .none

		case .hiddenAssetsButtonTapped:
			state.destination = .hiddenAssets(.init())
			return .none

		case .themeSelectionButtonTapped:
			state.destination = .themeSelection(.init())
			return .none

		case .gatewaysButtonTapped:
			state.destination = .gateways(.init())
			return .none

		case let .developerModeToogled(isEnabled):
			userDefaults.setPreferredTheme(isEnabled ? .light : .dark)
			state.appPreferences?.security.isDeveloperModeEnabled = isEnabled
			guard let preferences = state.appPreferences else { return .none }
			return .run { _ in
				try await appPreferencesClient.updatePreferences(preferences)
			} catch: { error, _ in
				errorQueue.schedule(error)
			}

		case let .advancedLockToogled(isEnabled):
			return .run { send in
				let authResult = await TaskResult<Bool> {
					try await localAuthenticationClient.authenticateWithBiometrics()
				}
				await send(.internal(.advancedLockToggleResult(authResult: authResult, isEnabled: isEnabled)))
			}

		case .exportLogsButtonTapped:
			state.exportLogsUrl = Logger.logFilePath
			return .none

		case .exportLogsDismissed:
			state.exportLogsUrl = nil
			return .none
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .loadedAppPreferences(appPreferences):
			state.appPreferences = appPreferences
			return .none

		case let .advancedLockToggleResult(.failure(error), _):
			errorQueue.schedule(error)
			return .none

		case let .advancedLockToggleResult(.success(success), isEnabled):
			guard success else { return .none }
			return updateAdvancedLock(state: &state, isEnabled: isEnabled)
		}
	}

	func reduceDismissedDestination(into state: inout State) -> Effect<Action> {
		guard case let .depositGuarantees(depositGuarantees) = state.destination, let value = depositGuarantees.depositGuarantee else {
			return .none
		}
		state.appPreferences?.transaction.defaultDepositGuarantee = value
		return savePreferences(state: state)
	}

	private func savePreferences(state: State) -> Effect<Action> {
		guard let preferences = state.appPreferences else { return .none }
		return .run { _ in
			try await appPreferencesClient.updatePreferences(preferences)
		}
	}

	private func updateAdvancedLock(state: inout State, isEnabled: Bool) -> Effect<Action> {
		state.appPreferences?.security.isAdvancedLockEnabled = isEnabled
		guard let preferences = state.appPreferences else { return .none }
		return .run { _ in
			try await appPreferencesClient.updatePreferences(preferences)
		} catch: { error, _ in
			errorQueue.schedule(error)
		}
	}
}
