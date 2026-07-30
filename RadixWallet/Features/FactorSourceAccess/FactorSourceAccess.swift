// MARK: - FactorSourceAccess
@Reducer
struct FactorSourceAccess: FeatureReducer {
	@ObservableState
	struct State: Hashable {
		enum AccessMode: Hashable {
			/// Ready to perform normal factor-source access or retry a cancelled read.
			case automatic

			/// A Device mnemonic read is in flight; retry must remain disabled.
			case loadingDeviceMnemonic

			/// Secure storage failed and the current sheet owns manual mnemonic entry.
			case manualDeviceMnemonic

			/// A terminal delegate action was sent; late effect output must be ignored.
			case completed
		}

		let id: FactorSourceId
		let purpose: Purpose
		var accessMode: AccessMode
		var factorSource: FactorSource?

		@Presents
		var destination: Destination.State? = nil

		var password: PasswordFactorSourceAccess.State?
		var deviceMnemonic: DeviceMnemonicFactorSourceAccess.State?
		var offDeviceMnemonic: OffDeviceMnemonicFactorSourceAccess.State?
		var arculus: ArculusFactorSourceAccess.State?

		var kind: FactorSourceKind {
			id.kind
		}

		init(id: FactorSourceIdFromHash, purpose: Purpose) {
			self.id = id.asGeneral
			self.purpose = purpose
			self.accessMode = .automatic
		}

		init(factorSource: FactorSource, purpose: Purpose) {
			self.id = factorSource.id
			self.purpose = purpose
			self.accessMode = .automatic
			self.factorSource = factorSource
		}
	}

	typealias Action = FeatureAction<Self>

	enum ViewAction: Hashable {
		case onFirstTask
		case retryButtonTapped
		case skipButtonTapped
		case closeButtonTapped
	}

	enum InternalAction: Hashable {
		case deviceMnemonicLoadCancelled
		case deviceMnemonicLoadFailed
		case deviceMnemonicLoaded(DeviceFactorSource, MnemonicWithPassphrase)
		case deviceMnemonicUnavailable(DeviceFactorSource, persistence: DeviceMnemonicFactorSourceAccess.Persistence)
		case hasP2PLinks(Bool)
		case setFactorSource(FactorSource?)
	}

	@CasePathable
	enum ChildAction: Hashable {
		case password(PasswordFactorSourceAccess.Action)
		case deviceMnemonic(DeviceMnemonicFactorSourceAccess.Action)
		case offDeviceMnemonic(OffDeviceMnemonicFactorSourceAccess.Action)
		case arculus(ArculusFactorSourceAccess.Action)
	}

	enum DelegateAction: Hashable {
		case perform(PrivateFactorSource)
		case cancel
		case skip
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Hashable {
			case errorAlert(AlertState<ErrorAlert>)
		}

		@CasePathable
		enum Action: Hashable {
			case errorAlert(ErrorAlert)
		}

		var body: some ReducerOf<Self> {
			EmptyReducer()
		}

		enum ErrorAlert: Hashable {
			case okTapped
		}
	}

	@Dependency(\.deviceFactorSourceClient) var deviceFactorSourceClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.p2pLinksClient) var p2pLinksClient

	private enum CancelID: Hashable {
		case deviceMnemonicLoad(FactorSourceId)
	}

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: \.destination) {
				Destination()
			}
			.ifLet(\.password, action: \.child.password) {
				PasswordFactorSourceAccess()
			}
			.ifLet(\.deviceMnemonic, action: \.child.deviceMnemonic) {
				DeviceMnemonicFactorSourceAccess()
			}
			.ifLet(\.offDeviceMnemonic, action: \.child.offDeviceMnemonic) {
				OffDeviceMnemonicFactorSourceAccess()
			}
			.ifLet(\.arculus, action: \.child.arculus) {
				ArculusFactorSourceAccess()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .onFirstTask:
			guard state.accessMode == .automatic else {
				return .none
			}
			if let deviceFactorSource = state.factorSource?.asDevice {
				state.accessMode = .loadingDeviceMnemonic
				return loadDeviceMnemonic(deviceFactorSource)
					.merge(with: checkP2PLinksEffect(state: state))
			}
			return fetchFactorSource(state: state)
				.merge(with: checkP2PLinksEffect(state: state))

		case .retryButtonTapped:
			guard state.accessMode == .automatic else {
				return .none
			}
			if let deviceFactorSource = state.factorSource?.asDevice {
				state.accessMode = .loadingDeviceMnemonic
				return loadDeviceMnemonic(deviceFactorSource)
			}
			guard let privateFactorSource = state.factorSource?.asPrivate else {
				return .none
			}
			return .send(.delegate(.perform(privateFactorSource)))

		case .skipButtonTapped:
			state.accessMode = .completed
			state.deviceMnemonic = nil
			return .concatenate(
				.cancel(id: CancelID.deviceMnemonicLoad(state.id)),
				.send(.delegate(.skip))
			)

		case .closeButtonTapped:
			state.accessMode = .completed
			state.deviceMnemonic = nil
			return .concatenate(
				.cancel(id: CancelID.deviceMnemonicLoad(state.id)),
				.send(.delegate(.cancel))
			)
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case .deviceMnemonicLoadCancelled, .deviceMnemonicLoadFailed:
			guard state.accessMode == .loadingDeviceMnemonic else {
				return .none
			}
			state.accessMode = .automatic
			return .none

		case let .deviceMnemonicLoaded(factorSource, mnemonicWithPassphrase):
			guard state.accessMode == .loadingDeviceMnemonic else {
				return .none
			}
			guard factorSource.id.spotCheck(input: .software(mnemonicWithPassphrase: mnemonicWithPassphrase)) else {
				state.accessMode = .manualDeviceMnemonic
				state.deviceMnemonic = .init(factorSource: factorSource, persistence: .ephemeral)
				return .none
			}
			state.accessMode = .completed
			state.deviceMnemonic = nil
			return .send(.delegate(.perform(.device(factorSource, mnemonicWithPassphrase))))

		case let .deviceMnemonicUnavailable(factorSource, persistence):
			guard state.accessMode == .loadingDeviceMnemonic else {
				return .none
			}
			state.accessMode = .manualDeviceMnemonic
			state.deviceMnemonic = .init(factorSource: factorSource, persistence: persistence)
			return .none

		case let .setFactorSource(factorSource):
			guard state.accessMode != .completed else {
				return .none
			}
			guard let factorSource else {
				assertionFailure("No Factor Source found on Profile for id: \(String(describing: state.id))")
				return .send(.delegate(.cancel))
			}
			state.factorSource = factorSource
			switch factorSource {
			case let .device(value):
				state.accessMode = .loadingDeviceMnemonic
				return loadDeviceMnemonic(value)

			case let .ledger(value):
				return .send(.delegate(.perform(.ledger(value))))

			case let .arculusCard(value):
				if state.purpose.requiresSignature {
					state.arculus = .init(factorSource: value)
					return .none
				}
				// Only signature requires user to provide a signature
				return .send(.delegate(.perform(.arculusCard(value, ""))))

			case let .password(value):
				state.password = .init(factorSource: value)
				return .none

			case let .offDeviceMnemonic(value):
				state.offDeviceMnemonic = .init(factorSource: value)
				return .none
			}

		case let .hasP2PLinks(hasP2PLinks):
			if !hasP2PLinks {
				state.destination = .errorAlert(.noP2Plink)
			}
			return .none
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .deviceMnemonic(.delegate(.perform(mnemonicWithPassphrase))):
			guard state.accessMode == .manualDeviceMnemonic else {
				return .none
			}
			guard let deviceFactorSource = state.factorSource?.asDevice else {
				assertionFailure("Expected DeviceFactorSource during manual mnemonic access")
				return .none
			}
			state.accessMode = .completed
			state.deviceMnemonic = nil
			return .send(.delegate(.perform(.device(deviceFactorSource, mnemonicWithPassphrase))))
		case let .arculus(.delegate(.perform(factorSource))):
			return .send(.delegate(.perform(factorSource)))
		case let .offDeviceMnemonic(.delegate(.perform(factorSource))):
			return .send(.delegate(.perform(factorSource)))
		default:
			return .none
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .errorAlert(.okTapped):
			state.destination = nil
			return .run { send in
				// Dispatching this in an async process is enough for it to take place after alert has been dismissed.
				// No need to place an actual delay with continuousClock.
				await send(.delegate(.cancel))
			}
		}
	}
}

private extension FactorSourceAccess {
	func loadDeviceMnemonic(_ factorSource: DeviceFactorSource) -> Effect<Action> {
		.run { send in
			do {
				let mnemonicWithPassphrase = try deviceFactorSourceClient.loadMnemonic(factorSource.id)
				try Task.checkCancellation()
				await send(.internal(.deviceMnemonicLoaded(factorSource, mnemonicWithPassphrase)))
			} catch is CancellationError {
				return
			} catch DeviceMnemonicLoadError.cancelledByUser {
				guard !Task.isCancelled else { return }
				await send(.internal(.deviceMnemonicLoadCancelled))
			} catch DeviceMnemonicLoadError.missing {
				guard !Task.isCancelled else { return }
				await send(.internal(.deviceMnemonicUnavailable(factorSource, persistence: .saveAfterValidation)))
			} catch DeviceMnemonicLoadError.readFailure {
				guard !Task.isCancelled else { return }
				await send(.internal(.deviceMnemonicUnavailable(factorSource, persistence: .ephemeral)))
			} catch {
				guard !Task.isCancelled else { return }
				errorQueue.schedule(error)
				await send(.internal(.deviceMnemonicLoadFailed))
			}
		}
		.cancellable(id: CancelID.deviceMnemonicLoad(factorSource.id.asGeneral), cancelInFlight: true)
	}

	func fetchFactorSource(state: State) -> Effect<Action> {
		if let factorSource = state.factorSource {
			// FactorSource was provided on init, no need to fetch it
			.send(.internal(.setFactorSource(factorSource)))
		} else {
			// Fetch FactorSource from its id
			.run { [id = state.id] send in
				let factorSource = try await factorSourcesClient.getFactorSource(id: id)
				await send(.internal(.setFactorSource(factorSource)))
			}
		}
	}

	func checkP2PLinksEffect(state: State) -> Effect<Action> {
		guard case .ledgerHqHardwareWallet = state.kind else {
			return .none
		}
		return .run { send in
			let result = await p2pLinksClient.hasP2PLinks()
			await send(.internal(.hasP2PLinks(result)))
		} catch: { error, _ in
			loggerGlobal.error("failed to check if has p2p links, error: \(error)")
		}
	}
}

private extension AlertState<FactorSourceAccess.Destination.ErrorAlert> {
	static var noP2Plink: AlertState {
		AlertState {
			TextState(L10n.LedgerHardwareDevices.LinkConnectorAlert.title)
		} actions: {
			ButtonState(action: .okTapped) {
				TextState(L10n.Common.ok)
			}
		} message: {
			TextState(L10n.LedgerHardwareDevices.LinkConnectorAlert.message)
		}
	}
}

private extension FactorSource {
	var asPrivate: PrivateFactorSource? {
		switch self {
		case .device:
			nil // Device access must first resolve its mnemonic.
		case let .ledger(value):
			.ledger(value)
		case let .arculusCard(value):
			.arculusCard(value, "")
		case .offDeviceMnemonic, .password:
			nil // User needs to manually input it
		}
	}
}

// MARK: - DeviceMnemonicFactorSourceAccess
@Reducer
struct DeviceMnemonicFactorSourceAccess: FeatureReducer {
	enum Persistence: Hashable {
		/// Use the supplied mnemonic only for the pending operation.
		case ephemeral

		/// Save the supplied mnemonic after it matches the existing factor source.
		case saveAfterValidation
	}

	@ObservableState
	struct State: Hashable {
		let factorSource: DeviceFactorSource
		let persistence: Persistence
		var grid: ImportMnemonicGrid.State
		var bip39Passphrase = ""
		var isAdvancedMode = false
		var isProcessing = false
		var lastSpotCheckFailed = false

		init(
			factorSource: DeviceFactorSource,
			persistence: Persistence = .ephemeral
		) {
			self.factorSource = factorSource
			self.persistence = persistence
			self.grid = .init(count: factorSource.hint.mnemonicWordCount)
		}

		var confirmButtonControlState: ControlState {
			guard !isProcessing, !lastSpotCheckFailed, grid.mnemonic != nil else {
				return .disabled
			}
			return .enabled
		}

		var hint: Hint.ViewState? {
			if lastSpotCheckFailed {
				Hint.ViewState.iconError(L10n.FactorSourceActions.OffDeviceMnemonic.wrong)
			} else if grid.isComplete, grid.mnemonic == nil {
				Hint.ViewState.iconError(L10n.FactorSourceActions.OffDeviceMnemonic.invalid)
			} else {
				nil
			}
		}
	}

	typealias Action = FeatureAction<Self>

	@CasePathable
	enum ViewAction: Hashable {
		case confirmButtonTapped
		case passphraseChanged(String)
		case toggleModeButtonTapped
	}

	@CasePathable
	enum ChildAction: Hashable {
		case grid(ImportMnemonicGrid.Action)
	}

	enum DelegateAction: Hashable {
		case perform(MnemonicWithPassphrase)
	}

	@Dependency(\.secureStorageClient) var secureStorageClient
	@Dependency(\.errorQueue) var errorQueue

	var body: some ReducerOf<Self> {
		Scope(state: \.grid, action: \.child.grid) {
			ImportMnemonicGrid()
		}
		Reduce(core)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .confirmButtonTapped:
			guard !state.isProcessing, let mnemonic = state.grid.mnemonic else {
				return .none
			}
			let mnemonicWithPassphrase = MnemonicWithPassphrase(
				mnemonic: mnemonic,
				passphrase: state.bip39Passphrase
			)
			guard state.factorSource.id.spotCheck(input: .software(mnemonicWithPassphrase: mnemonicWithPassphrase)) else {
				state.lastSpotCheckFailed = true
				return .none
			}
			state.isProcessing = true
			guard state.persistence == .saveAfterValidation else {
				return .send(.delegate(.perform(mnemonicWithPassphrase)))
			}

			let privateFactorSource = PrivateHierarchicalDeterministicFactorSource(
				mnemonicWithPassphrase: mnemonicWithPassphrase,
				factorSource: state.factorSource
			)
			return .run { send in
				do {
					try secureStorageClient.saveMnemonicForFactorSource(privateFactorSource)
				} catch {
					errorQueue.schedule(error)
				}
				guard !Task.isCancelled else { return }
				await send(.delegate(.perform(mnemonicWithPassphrase)))
			}

		case let .passphraseChanged(passphrase):
			state.bip39Passphrase = passphrase
			state.lastSpotCheckFailed = false
			return .none

		case .toggleModeButtonTapped:
			state.isAdvancedMode.toggle()
			return .none
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .grid(.delegate(.didUpdateGrid)):
			state.lastSpotCheckFailed = false
			return .none
		default:
			return .none
		}
	}
}
