// MARK: - ImportMnemonicForFactorSource
@Reducer
struct ImportMnemonicForFactorSource: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		let deviceFactorSource: DeviceFactorSource
		let profileToCheck: ProfileToCheck
		let isAllowedToSkip: Bool

		var entitiesLinkedToFactorSource: Loadable<EntitiesLinkedToFactorSource> = .idle
		var grid: ImportMnemonicGrid.State
		fileprivate var lastSpotCheckFailed = false

		var confirmButtonControlState: ControlState {
			if lastSpotCheckFailed {
				return .disabled
			}
			switch status {
			case .incomplete, .invalid:
				return .disabled
			case .readyForSpotCheck:
				return .enabled
			}
		}

		init(
			isAllowedToSkip: Bool = false,
			deviceFactorSource: DeviceFactorSource,
			profileToCheck: ProfileToCheck
		) {
			self.isAllowedToSkip = isAllowedToSkip
			self.deviceFactorSource = deviceFactorSource
			self.grid = .init(
				count: deviceFactorSource.hint.mnemonicWordCount
			)
			self.profileToCheck = profileToCheck
		}
	}

	typealias Action = FeatureAction<Self>

	enum ViewAction: Sendable, Equatable {
		case task
		case skipButtonTapped
		case confirmButtonTapped
		case closeButtonTapped
	}

	enum InternalAction: Sendable, Equatable {
		case entitieLinkedLoadResult(TaskResult<EntitiesLinkedToFactorSource>)
	}

	@CasePathable
	enum ChildAction: Sendable, Hashable {
		case grid(ImportMnemonicGrid.Action)
	}

	enum DelegateAction: Sendable, Hashable {
		case skipped(DeviceFactorSource)
		case imported(DeviceFactorSource)
		case closed
	}

	@Dependency(\.deviceFactorSourceClient) var deviceFactorSourceClient
	@Dependency(\.secureStorageClient) var secureStorageClient
	@Dependency(\.userDefaults) var userDefaults
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.overlayWindowClient) var overlayWindowClient

	var body: some ReducerOf<Self> {
		Scope(state: \.grid, action: \.child.grid) {
			ImportMnemonicGrid()
		}
		Reduce(core)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			let fs = state.deviceFactorSource
			state.entitiesLinkedToFactorSource = .loading
			let profileToCheck = state.profileToCheck
			return .run { send in
				let result = await TaskResult { try await SargonOS.shared.entitiesLinkedToFactorSource(factorSource: fs.asGeneral, profileToCheck: profileToCheck) }
				await send(.internal(.entitieLinkedLoadResult(result)))
			}

		case .skipButtonTapped:
			return .send(.delegate(.skipped(state.deviceFactorSource)))

		case .confirmButtonTapped:
			guard let mnemonicWithPassphrase = state.mnemonicWithPassphrase,
			      let accounts = state.entitiesLinkedToFactorSource.wrappedValue?.allAccounts
			else {
				return .none
			}

			guard state.deviceFactorSource.id.spotCheck(input: .software(mnemonicWithPassphrase: mnemonicWithPassphrase)) else {
				state.lastSpotCheckFailed = true
				return .none
			}

			let factorSource = state.deviceFactorSource
			return .run { send in
				try mnemonicWithPassphrase.validatePublicKeys(of: accounts)

				let privateHDFactorSource = PrivateHierarchicalDeterministicFactorSource(
					mnemonicWithPassphrase: mnemonicWithPassphrase,
					factorSource: factorSource
				)

				try secureStorageClient.saveMnemonicForFactorSource(privateHDFactorSource)
				try userDefaults.addFactorSourceIDOfBackedUpMnemonic(privateHDFactorSource.factorSource.id)

				overlayWindowClient.scheduleHUD(.seedPhraseImported)
				await send(.delegate(.imported(factorSource)))
			} catch: { err, _ in
				errorQueue.schedule(err)
			}

		case .closeButtonTapped:
			return .send(.delegate(.closed))
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .entitieLinkedLoadResult(result):
			state.entitiesLinkedToFactorSource.refresh(from: .init(result: result))
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

extension ImportMnemonicForFactorSource.State {
	/// An enum describing the different errors that can take place from user's input.
	enum Status: Sendable, Hashable {
		/// User hasn't entered every word yet.
		case incomplete

		/// User has entered every word but a Mnemonic cannot be built from it (checksum fails).
		case invalid

		/// The entered mnemonic is complete (checksum succeeds), now user needs to tap on Continue
		/// button to perform the spot check.
		case readyForSpotCheck(MnemonicWithPassphrase)
	}

	var status: Status {
		if !isComplete {
			.incomplete
		} else if let mnemonicWithPassphrase {
			.readyForSpotCheck(mnemonicWithPassphrase)
		} else {
			.invalid
		}
	}

	var hint: Hint.ViewState? {
		if lastSpotCheckFailed {
			Hint.ViewState.iconError(L10n.FactorSourceActions.OffDeviceMnemonic.wrong)
		} else if status == .invalid {
			Hint.ViewState.iconError(L10n.FactorSourceActions.OffDeviceMnemonic.invalid)
		} else {
			nil
		}
	}
}

private extension ImportMnemonicForFactorSource.State {
	var mnemonicWithPassphrase: MnemonicWithPassphrase? {
		guard let mnemonic = try? Mnemonic(words: completedWords) else {
			return nil
		}
		return .init(mnemonic: mnemonic)
	}

	var isComplete: Bool {
		completedWords.count == grid.words.count
	}

	var completedWords: [BIP39Word] {
		grid.words.compactMap(\.completeWord)
	}
}

extension EntitiesLinkedToFactorSource {
	var allAccounts: [Account] {
		self.accounts + self.hiddenAccounts
	}
}
