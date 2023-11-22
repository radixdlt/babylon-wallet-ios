// MARK: - RecoverWalletWithoutProfileCoordinator

public struct RecoverWalletWithoutProfileCoordinator: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var root: RecoverWalletWithoutProfileStart.State
		public var path: StackState<Path.State> = .init()

		/// SHOULD be used to delete the mnemonic if user did not complete
		/// the account recovery scanning flow. Will be added to Profile
		/// as main BDFS if account recovery scanning flow is completed.
		public var factorSourceOfImportedMnemonic: DeviceFactorSource?

		@PresentationState
		var destination: Destination.State? = nil

		public init() {
			self.root = .init()
		}
	}

	public struct Path: Sendable, Hashable, Reducer {
		public enum State: Sendable, Hashable {
			case recoverWalletControlWithBDFSOnly(RecoverWalletControlWithBDFSOnly.State)
			case importMnemonic(ImportMnemonic.State)
			case recoveryComplete(RecoverWalletControlWithBDFSComplete.State)
		}

		public enum Action: Sendable, Equatable {
			case recoverWalletControlWithBDFSOnly(RecoverWalletControlWithBDFSOnly.Action)
			case importMnemonic(ImportMnemonic.Action)
			case recoveryComplete(RecoverWalletControlWithBDFSComplete.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.recoverWalletControlWithBDFSOnly, action: /Action.recoverWalletControlWithBDFSOnly) {
				RecoverWalletControlWithBDFSOnly()
			}

			Scope(state: /State.importMnemonic, action: /Action.importMnemonic) {
				ImportMnemonic()
			}

			Scope(state: /State.recoveryComplete, action: /Action.recoveryComplete) {
				RecoverWalletControlWithBDFSComplete()
			}
		}
	}

	public struct Destination: DestinationReducer {
		public enum State: Hashable, Sendable {
			case accountRecoveryScanCoordinator(AccountRecoveryScanCoordinator.State)
		}

		public enum Action: Equatable, Sendable {
			case accountRecoveryScanCoordinator(AccountRecoveryScanCoordinator.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.accountRecoveryScanCoordinator, action: /Action.accountRecoveryScanCoordinator) {
				AccountRecoveryScanCoordinator()
			}
		}
	}

	public enum ChildAction: Sendable, Equatable {
		case root(RecoverWalletWithoutProfileStart.Action)
		case path(StackActionOf<Path>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismiss
		case backToStartOfOnboarding
		case profileCreatedFromImportedBDFS
	}

	@Dependency(\.secureStorageClient) var secureStorageClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.dismiss) var dismiss
	@Dependency(\.device) var device

	public init() {}

	public var body: some ReducerOf<Self> {
		Scope(state: \.root, action: /Action.child .. ChildAction.root) {
			RecoverWalletWithoutProfileStart()
		}

		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
			.forEach(\.path, action: /Action.child .. ChildAction.path) {
				Path()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .root(.delegate(.backToStartOfOnboarding)):
			return .send(.delegate(.backToStartOfOnboarding))
		case .root(.delegate(.dismiss)):
			return .run { _ in
				await dismiss()
			}
		case .root(.delegate(.recoverWithBDFSOnly)):
			state.path.append(.recoverWalletControlWithBDFSOnly(.init()))
			return .none

		case .path(.element(_, action: .recoverWalletControlWithBDFSOnly(.delegate(.continue)))):
			state.path.append(
				.importMnemonic(
					.init(
						// We SHOULD remove the mnemonic from keychain if it we do not
						// complete this flow.
						persistStrategy: .init(
							mnemonicForFactorSourceKind: .onDevice(
								.babylon
							),
							location: .intoKeychainOnly
						)
					)
				)
			)
			return .none

		case let .path(.element(_, action: .importMnemonic(.delegate(delegateAction)))):
			switch delegateAction {
			case let .persistedMnemonicInKeychainOnly(factorSource):
				guard let fromHash = factorSource.id.extract(FactorSource.ID.FromHash.self) else {
					fatalError("error handling")
				}
				let deviceFactorSource = DeviceFactorSource(id: fromHash, common: .init(), hint: .init(name: "iPhone", model: "iPhone", mnemonicWordCount: .twentyFour))
				state.factorSourceOfImportedMnemonic = deviceFactorSource
				state.destination = .accountRecoveryScanCoordinator(.init(purpose: .createProfile(deviceFactorSource), promptForSelectionOfInactiveAccountsIfAny: true))
				return .none

			default:
				let errorMsg = "Discrepancy! Expected to have saved mnemonic into keychain but other action happened: \(delegateAction)"
				loggerGlobal.error(.init(stringLiteral: errorMsg))
				assertionFailure(errorMsg)
				return .send(.delegate(.dismiss))
			}

		case .path(.element(_, action: .recoveryComplete(.delegate(.profileCreatedFromImportedBDFS)))):
			return .send(.delegate(.profileCreatedFromImportedBDFS))

		default: return .none
		}
	}

	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .accountRecoveryScanCoordinator(.delegate(.completed)):
			state.destination = nil
			state.path.append(.recoveryComplete(.init()))
			return .none

		case .accountRecoveryScanCoordinator(.delegate(.dismissed)):
			return deleteSavedUnusedMnemonic(state: state)

		default: return .none
		}
	}

	public func reduceDismissedDestination(into state: inout State) -> Effect<Action> {
		deleteSavedUnusedMnemonic(state: state)
	}

	private func deleteSavedUnusedMnemonic(state: State) -> Effect<Action> {
		if
			let factorSourceID = state.factorSourceOfImportedMnemonic?.id
		{
			loggerGlobal.notice("We did not finish Account Recovery Scan Flow. Deleting mnemonic from keychain for safety reasons.")
			// We did not complete account recovery scan => delete the mnemonic from
			// keychain for security reasons.
			try? secureStorageClient.deleteMnemonicByFactorSourceID(factorSourceID)
		}
		return .send(.delegate(.dismiss))
	}
}
