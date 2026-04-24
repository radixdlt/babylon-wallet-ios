import Sargon

// MARK: - Preferences

struct Preferences: FeatureReducer {
	@Environment(\.colorScheme) var colorScheme
	struct State: Hashable {
		var appPreferences: AppPreferences?
		var exportLogsUrl: URL?

		@PresentationState
		var destination: Destination.State?

		init() {}
	}

	enum ViewAction: Equatable {
		case appeared
		case depositGuaranteesButtonTapped
		case hiddenEntitiesButtonTapped
		case hiddenAssetsButtonTapped
		case addressBookButtonTapped
		case themeSelectionButtonTapped
		case gatewaysButtonTapped
		case signalingServersButtonTapped
		case relayServicesButtonTapped
		case tokenPriceServicesButtonTapped
		case developerModeToogled(Bool)
		case advancedLockToogled(Bool)
		case exportLogsButtonTapped
		case exportLogsDismissed
	}

	enum InternalAction: Equatable {
		case loadedAppPreferences(AppPreferences)
		case advancedLockToggleResult(authResult: TaskResult<Bool>, isEnabled: Bool)
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Hashable {
			case depositGuarantees(DefaultDepositGuarantees.State)
			case hiddenEntities(HiddenEntities.State)
			case hiddenAssets(HiddenAssets.State)
			case addressBook(AddressBook.State)
			case themeSelection(ThemeSelection.State)
			case gateways(GatewaySettings.State)
			case signalingServers(SignalingServersSettings.State)
			case relayServices(RelayServicesSettings.State)
			case tokenPriceServices(TokenPriceServicesSettings.State)
		}

		@CasePathable
		enum Action: Equatable {
			case depositGuarantees(DefaultDepositGuarantees.Action)
			case hiddenEntities(HiddenEntities.Action)
			case hiddenAssets(HiddenAssets.Action)
			case addressBook(AddressBook.Action)
			case themeSelection(ThemeSelection.Action)
			case gateways(GatewaySettings.Action)
			case signalingServers(SignalingServersSettings.Action)
			case relayServices(RelayServicesSettings.Action)
			case tokenPriceServices(TokenPriceServicesSettings.Action)
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
			Scope(state: \.addressBook, action: \.addressBook) {
				AddressBook()
			}
			Scope(state: \.themeSelection, action: \.themeSelection) {
				ThemeSelection()
			}
			Scope(state: \.gateways, action: \.gateways) {
				GatewaySettings()
			}
			Scope(state: \.signalingServers, action: \.signalingServers) {
				SignalingServersSettings()
			}
			Scope(state: \.relayServices, action: \.relayServices) {
				RelayServicesSettings()
			}
			Scope(state: \.tokenPriceServices, action: \.tokenPriceServices) {
				TokenPriceServicesSettings()
			}
		}
	}

	@Dependency(\.appPreferencesClient) var appPreferencesClient
	@Dependency(\.localAuthenticationClient) var localAuthenticationClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.userDefaults) var userDefaults

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

		case .addressBookButtonTapped:
			state.destination = .addressBook(.init())
			return .none

		case .themeSelectionButtonTapped:
			state.destination = .themeSelection(.init())
			return .none

		case .gatewaysButtonTapped:
			state.destination = .gateways(.init())
			return .none

		case .signalingServersButtonTapped:
			state.destination = .signalingServers(.init())
			return .none

		case .relayServicesButtonTapped:
			state.destination = .relayServices(.init())
			return .none

		case .tokenPriceServicesButtonTapped:
			state.destination = .tokenPriceServices(.init(
				isDeveloperModeEnabled: state.appPreferences?.security.isDeveloperModeEnabled ?? false
			))
			return .none

		case let .developerModeToogled(isEnabled):
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

// MARK: - TokenPriceServicesSettings
struct TokenPriceServicesSettings: FeatureReducer {
	@ObservableState
	struct State: Hashable {
		struct Row: Hashable, Identifiable {
			var id: URL {
				service.baseUrl
			}

			let service: TokenPriceService
		}

		var rows: IdentifiedArrayOf<Row> = []
		var isDeveloperModeEnabled: Bool

		@Presents
		var destination: Destination.State? = nil

		init(isDeveloperModeEnabled: Bool = false) {
			self.isDeveloperModeEnabled = isDeveloperModeEnabled
		}
	}

	typealias Action = FeatureAction<Self>

	@CasePathable
	enum ViewAction: Equatable {
		case task
		case addButtonTapped
		case deleteTapped(URL)
	}

	enum InternalAction: Equatable {
		case servicesLoaded([TokenPriceService])
		case deleteResult(TaskResult<EqVoid>)
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Hashable {
			case addService(AddTokenPriceService.State)
			case deleteAlert(AlertState<DeleteAlert>)
		}

		@CasePathable
		enum Action: Equatable {
			case addService(AddTokenPriceService.Action)
			case deleteAlert(DeleteAlert)
		}

		enum DeleteAlert: Hashable {
			case removeButtonTapped(URL)
			case cancelButtonTapped
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.addService, action: \.addService) {
				AddTokenPriceService()
			}
		}
	}

	@Dependency(\.tokenPricesClient) var tokenPricesClient
	@Dependency(\.errorQueue) var errorQueue

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(\.$destination, action: \.destination) {
				Destination()
			}
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			return loadServices()

		case .addButtonTapped:
			state.destination = .addService(.init(
				existingBaseURLs: Set(state.rows.map(\.service.baseUrl)),
				isDeveloperModeEnabled: state.isDeveloperModeEnabled
			))
			return .none

		case let .deleteTapped(baseURL):
			state.destination = .deleteAlert(.removeService(baseURL: baseURL))
			return .none
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .servicesLoaded(services):
			state.rows = .init(uniqueElements: services.sortedForDisplay().map(State.Row.init(service:)))
			return .none

		case let .deleteResult(.failure(error)):
			errorQueue.schedule(error)
			return .none

		case .deleteResult(.success):
			state.destination = nil
			return loadServices()
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .addService(.delegate(.saved)):
			state.destination = nil
			return loadServices()

		case let .deleteAlert(.removeButtonTapped(baseURL)):
			return .run { send in
				let result = await TaskResult {
					let deleted = try await tokenPricesClient.deleteTokenPriceService(baseURL)
					guard deleted else { throw TokenPriceServicesSettingsError.operationFailed }
					return EqVoid.instance
				}
				await send(.internal(.deleteResult(result)))
			}

		case .deleteAlert(.cancelButtonTapped):
			state.destination = nil
			return .none

		default:
			return .none
		}
	}

	private func loadServices() -> Effect<Action> {
		.run { send in
			let services = try tokenPricesClient.getTokenPriceServices()
			await send(.internal(.servicesLoaded(services)))
		} catch: { error, _ in
			errorQueue.schedule(error)
		}
	}
}

// MARK: - AddTokenPriceService
@Reducer
struct AddTokenPriceService: FeatureReducer {
	@ObservableState
	struct State: Hashable {
		enum Field: Hashable {
			case url
		}

		var existingBaseURLs: Set<URL>
		var isDeveloperModeEnabled: Bool
		var focusedField: Field?
		var url: String = ""
		var parsedURL: URL?
		var errorText: String?
		var addButtonState: ControlState = .disabled

		init(existingBaseURLs: Set<URL> = [], isDeveloperModeEnabled: Bool = false) {
			self.existingBaseURLs = existingBaseURLs
			self.isDeveloperModeEnabled = isDeveloperModeEnabled
		}
	}

	typealias Action = FeatureAction<Self>

	@CasePathable
	enum ViewAction: Equatable {
		case appeared
		case textFieldFocused(State.Field?)
		case urlChanged(String)
		case addButtonTapped
	}

	enum InternalAction: Equatable {
		case focusTextField(State.Field?)
		case addResult(TaskResult<Bool>)
	}

	enum DelegateAction: Equatable {
		case saved
	}

	@Dependency(\.tokenPricesClient) var tokenPricesClient
	@Dependency(\.errorQueue) var errorQueue

	var body: some ReducerOf<Self> {
		Reduce(core)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			return .send(.internal(.focusTextField(.url)))

		case let .textFieldFocused(focus):
			return .send(.internal(.focusTextField(focus)))

		case let .urlChanged(url):
			state.url = url
			refreshValidation(state: &state)
			return .none

		case .addButtonTapped:
			guard let parsedURL = state.parsedURL else { return .none }
			state.addButtonState = .loading(.local)
			return .run { send in
				let result = await TaskResult {
					try await tokenPricesClient.addTokenPriceService(parsedURL)
				}
				await send(.internal(.addResult(result)))
			}
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .focusTextField(focus):
			state.focusedField = focus
			return .none

		case .addResult(.success(true)):
			return .send(.delegate(.saved))

		case .addResult(.success(false)):
			state.errorText = "Could not add token price service."
			state.addButtonState = .disabled
			return .none

		case let .addResult(.failure(error)):
			state.errorText = "Could not add token price service."
			state.addButtonState = .disabled
			errorQueue.schedule(error)
			return .none
		}
	}
}

extension AddTokenPriceService {
	static func tokenPriceServiceURL(from input: String, isDeveloperModeEnabled: Bool) -> URL? {
		let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
		guard !trimmed.isEmpty else { return nil }

		let urlString = if trimmed.contains("://") {
			trimmed
		} else if isDeveloperModeEnabled {
			"http://\(trimmed)"
		} else {
			"https://\(trimmed)"
		}

		guard
			let url = URL(string: urlString),
			let scheme = url.scheme?.lowercased(),
			["http", "https"].contains(scheme),
			url.host?.isEmpty == false
		else {
			return nil
		}

		return url
	}

	private func refreshValidation(state: inout State) {
		state.errorText = nil

		guard let parsedURL = Self.tokenPriceServiceURL(
			from: state.url,
			isDeveloperModeEnabled: state.isDeveloperModeEnabled
		) else {
			state.parsedURL = nil
			state.addButtonState = .disabled
			return
		}

		guard !state.existingBaseURLs.contains(parsedURL) else {
			state.parsedURL = nil
			state.errorText = "This URL has already been added."
			state.addButtonState = .disabled
			return
		}

		state.parsedURL = parsedURL
		state.addButtonState = .enabled
	}
}

// MARK: - TokenPriceServicesSettingsError
private enum TokenPriceServicesSettingsError: Error {
	case operationFailed
}

private extension AlertState where Action == TokenPriceServicesSettings.Destination.DeleteAlert {
	static func removeService(baseURL: URL) -> AlertState {
		AlertState {
			TextState("Remove Token Price Service")
		} actions: {
			ButtonState(role: .cancel, action: .cancelButtonTapped) {
				TextState(L10n.Common.cancel)
			}
			ButtonState(role: .destructive, action: .removeButtonTapped(baseURL)) {
				TextState(L10n.Common.remove)
			}
		} message: {
			TextState("This token price service will no longer be used to fetch token prices.")
		}
	}
}

private extension Sequence<TokenPriceService> {
	func sortedForDisplay() -> [TokenPriceService] {
		sorted {
			$0.baseUrl.absoluteString.localizedStandardCompare($1.baseUrl.absoluteString) == .orderedAscending
		}
	}
}
