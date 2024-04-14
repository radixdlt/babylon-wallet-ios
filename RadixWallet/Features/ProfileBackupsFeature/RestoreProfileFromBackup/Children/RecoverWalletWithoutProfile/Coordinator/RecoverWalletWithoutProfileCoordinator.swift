// MARK: - RecoverWalletWithoutProfileCoordinator

public struct RecoverWalletWithoutProfileCoordinator: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var root: Path.State?
		public var path: StackState<Path.State> = .init()

		/// Not saved into keychain yet
		public var factorSourceOfImportedMnemonic: PrivateHierarchicalDeterministicFactorSource?

		@PresentationState
		var destination: Destination.State? = nil

		public init() {
			self.root = .init(.start(.init()))
		}
	}

	public struct Path: Sendable, Hashable, Reducer {
		public enum State: Sendable, Hashable {
			case start(RecoverWalletWithoutProfileStart.State)
			case recoverWalletControlWithBDFSOnly(RecoverWalletControlWithBDFSOnly.State)
			case importMnemonic(ImportMnemonic.State)
			case recoveryComplete(RecoverWalletControlWithBDFSComplete.State)
		}

		public enum Action: Sendable, Equatable {
			case start(RecoverWalletWithoutProfileStart.Action)
			case recoverWalletControlWithBDFSOnly(RecoverWalletControlWithBDFSOnly.Action)
			case importMnemonic(ImportMnemonic.Action)
			case recoveryComplete(RecoverWalletControlWithBDFSComplete.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.start, action: /Action.start) {
				RecoverWalletWithoutProfileStart()
			}

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
		case root(Path.Action)
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
		Reduce(core)
			.ifLet(\.root, action: /Action.child .. ChildAction.root) {
				Path()
			}
			.forEach(\.path, action: /Action.child .. ChildAction.path) {
				Path()
			}
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .root(.start(.delegate(.backToStartOfOnboarding))):
			return .send(.delegate(.backToStartOfOnboarding))

		case .root(.start(.delegate(.dismiss))):
			return .run { _ in
				await dismiss()
			}

		case .root(.start(.delegate(.recoverWithBDFSOnly))):
			state.path.append(.recoverWalletControlWithBDFSOnly(.init()))
			return .none

		case .path(.element(_, action: .recoverWalletControlWithBDFSOnly(.delegate(.continue)))):
			state.path.append(
				.importMnemonic(
					.init(
						header: .init(title: L10n.EnterSeedPhrase.Header.titleMain),
						warning: L10n.EnterSeedPhrase.warning,
						hideAdvancedMode: true,
						// we require 24 word Babylon mnemonic
						isWordCountFixed: true,
						persistStrategy: nil,
						wordCount: .twentyFour
					)
				)
			)
			return .none

		case let .path(.element(_, action: .importMnemonic(.delegate(delegateAction)))):
			switch delegateAction {
			case let .notPersisted(mnemonicWithPassphrase):
//				do {
//					let mainBDFS = try DeviceFactorSource.babylon(
//						mnemonicWithPassphrase: mnemonicWithPassphrase,
//						isMain: true,
//						isOlympiaCompatible: false // FIXME: is this what we want?
//					)
//
//					let privateHD = try PrivateHierarchicalDeterministicFactorSource(
//						mnemonicWithPassphrase: mnemonicWithPassphrase,
//						factorSource: mainBDFS
//					)
//
//					state.factorSourceOfImportedMnemonic = privateHD
//					state.destination = .accountRecoveryScanCoordinator(.init(purpose: .createProfile(privateHD)))
//
//					return .none
//				} catch {
//					let errorMsg = "Failed to create Private HD FactorSource from MnemonicWithPassphrase, error: \(error)"
//					loggerGlobal.error(.init(stringLiteral: errorMsg))
//					assertionFailure(errorMsg)
//					return .send(.delegate(.dismiss))
//				}
				sargonProfileFinishMigrateAtEndOfStage1()

			default:
				let errorMsg = "Discrepancy! Expected to have saved mnemonic into keychain but other action happened: \(delegateAction)"
				loggerGlobal.error(.init(stringLiteral: errorMsg))
				assertionFailure(errorMsg)
				return .send(.delegate(.dismiss))
			}

		case .root(.recoveryComplete(.delegate(.profileCreatedFromImportedBDFS))):
			return .send(.delegate(.profileCreatedFromImportedBDFS))

		default:
			return .none
		}
	}

	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .accountRecoveryScanCoordinator(.delegate(.completed)):
			state.destination = nil
			state.path = .init()
			// replace root so we cannot go back from `recoveryComplete`
			state.root = .recoveryComplete(.init())
			return .none

		case .accountRecoveryScanCoordinator(.delegate(.dismissed)):
			state.path = .init()
			state.root = .start(.init())
			state.destination = nil
			return .none

		default:
			return .none
		}
	}
}
