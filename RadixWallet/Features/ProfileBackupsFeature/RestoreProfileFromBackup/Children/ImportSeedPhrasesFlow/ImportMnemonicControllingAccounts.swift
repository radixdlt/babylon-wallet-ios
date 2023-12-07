import ComposableArchitecture
import SwiftUI

// MARK: - ImportMnemonicControllingAccounts
public struct ImportMnemonicControllingAccounts: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public var id: EntitiesControlledByFactorSource.ID {
			entitiesControlledByFactorSource.id
		}

		public let entitiesControlledByFactorSource: EntitiesControlledByFactorSource

		public let entities: DisplayEntitiesControlledByMnemonic.State

		@PresentationState
		public var destination: Destination.State? = nil

		public var isMainBDFS: Bool

		public init(
			entitiesControlledByFactorSource: EntitiesControlledByFactorSource,
			isMainBDFS: Bool
		) {
			self.isMainBDFS = isMainBDFS
			self.entitiesControlledByFactorSource = entitiesControlledByFactorSource

			self.entities = .init(
				id: .mixingBabylonAndOlympiaAccounts(
					entitiesControlledByFactorSource.factorSourceID
				),
				isMnemonicMarkedAsBackedUp: entitiesControlledByFactorSource.isMnemonicMarkedAsBackedUp,
				isMnemonicPresentInKeychain: entitiesControlledByFactorSource.isMnemonicPresentInKeychain,
				accounts: (isMainBDFS ? entitiesControlledByFactorSource.babylonAccounts : entitiesControlledByFactorSource.olympiaAccounts)?.rawValue ?? [],
				hasHiddenAccounts: !entitiesControlledByFactorSource.hiddenAccounts.isEmpty,
				mode: .displayAccountListOnly
			)
		}
	}

	public enum InternalAction: Sendable, Equatable {
		case validated(PrivateHDFactorSource)
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case inputMnemonicButtonTapped
		case skipButtonTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case persistedMnemonicInKeychain(FactorSourceID.FromHash)
		case skippedMnemonic(FactorSourceID.FromHash)
		case createdNewMainBDFS(oldSkipped: FactorSourceID.FromHash, DeviceFactorSource)
		case failedToSaveInKeychain(FactorSourceID.FromHash)
	}

	public enum ChildAction: Sendable, Equatable {
		case entities(DisplayEntitiesControlledByMnemonic.Action)
	}

	// MARK: - Destination

	public struct Destination: DestinationReducer {
		public enum State: Sendable, Hashable {
			case importMnemonic(ImportMnemonic.State)
			case confirmSkippingBDFS(ConfirmSkippingBDFS.State)
		}

		public enum Action: Sendable, Equatable {
			case importMnemonic(ImportMnemonic.Action)
			/// **B**abylon **D**evice **F**actor **S**ource
			case confirmSkippingBDFS(ConfirmSkippingBDFS.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.importMnemonic, action: /Action.importMnemonic) {
				ImportMnemonic()
			}
			Scope(state: /State.confirmSkippingBDFS, action: /Action.confirmSkippingBDFS) {
				ConfirmSkippingBDFS()
			}
		}
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.secureStorageClient) var secureStorageClient
	@Dependency(\.overlayWindowClient) var overlayWindowClient
	@Dependency(\.userDefaults) var userDefaults
	@Dependency(\.factorSourcesClient) var factorSourcesClient

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
		case .appeared:
			return .none
		case .inputMnemonicButtonTapped:
			state.destination = .importMnemonic(.init(
				warning: L10n.RevealSeedPhrase.warning,
				isWordCountFixed: true,
				persistStrategy: nil,
				wordCount: state.entitiesControlledByFactorSource.mnemonicWordCount
			))
			return .none

		case .skipButtonTapped:
			if state.isMainBDFS {
				state.destination = .confirmSkippingBDFS(.init())
				return .none
			} else {
				return .send(.delegate(.skippedMnemonic(state.entitiesControlledByFactorSource.factorSourceID)))
			}
		}
	}

	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case let .importMnemonic(.delegate(delegateAction)):
			switch delegateAction {
			case let .notPersisted(mnemonicWithPassphrase):
				// FIXME: should always work... but please tidy up!
				let factorSourceID = try! FactorSourceID.FromHash(
					kind: .device,
					mnemonicWithPassphrase: mnemonicWithPassphrase
				)
				guard factorSourceID == state.entitiesControlledByFactorSource.factorSourceID else {
					overlayWindowClient.scheduleHUD(.wrongMnemonic)
					return .none
				}

				return validate(
					mnemonicWithPassphrase: mnemonicWithPassphrase,
					accounts: state.entitiesControlledByFactorSource.accounts,
					factorSource: state.entitiesControlledByFactorSource.deviceFactorSource
				)

			case .persistedMnemonicInKeychainOnly, .doneViewing, .persistedNewFactorSourceInProfile:
				preconditionFailure("Incorrect implementation")
			}

		case .confirmSkippingBDFS(.delegate(.cancel)):
			state.destination = nil
			return .none

		case .confirmSkippingBDFS(.delegate(.confirmed)):
			loggerGlobal.notice("Skipping BDFS! Generating a new one and hiding affected accounts/personas.")
			state.destination = nil
			return .run { [entitiesControlledByFactorSource = state.entitiesControlledByFactorSource] send in
				loggerGlobal.info("Generating mnemonic for new main BDFS")
				let newMainBDFS = try await factorSourcesClient.createNewMainBDFS()
				loggerGlobal.info("Delegating done with creating new BDFS (skipped old)")
				await send(.delegate(.createdNewMainBDFS(
					oldSkipped: entitiesControlledByFactorSource.factorSourceID,
					newMainBDFS.factorSource
				)))
			} catch: { error, _ in
				loggerGlobal.critical("Failed to create new main BDFS error: \(error)")
			}

		default:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .validated(privateHDFactorSource):
			state.destination = nil
			return .run { send in
				try userDefaults.addFactorSourceIDOfBackedUpMnemonic(privateHDFactorSource.factorSource.id)

				try secureStorageClient.saveMnemonicForFactorSource(
					privateHDFactorSource
				)

				await send(.delegate(.persistedMnemonicInKeychain(privateHDFactorSource.factorSource.id)))

			} catch: { error, send in
				errorQueue.schedule(error)
				loggerGlobal.error("Failed to saved mnemonic in keychain")
				await send(.delegate(.failedToSaveInKeychain(privateHDFactorSource.factorSource.id)))
			}
		}
	}

	private func validate(
		mnemonicWithPassphrase: MnemonicWithPassphrase,
		accounts: [Profile.Network.Account],
		factorSource: DeviceFactorSource
	) -> Effect<Action> {
		func fail(error: Swift.Error?) -> Effect<Action> {
			loggerGlobal.error("Failed to validate all accounts against mnemonic, underlying error: \(String(describing: error))")
			errorQueue.schedule(MnemonicDidNotValidateAllAccounts())
			return .none
		}
		do {
			guard try mnemonicWithPassphrase.validatePublicKeys(of: accounts) else {
				return fail(error: nil)
			}

			let privateHDFactorSource = try PrivateHDFactorSource(
				mnemonicWithPassphrase: mnemonicWithPassphrase,
				factorSource: factorSource
			)

			return .send(.internal(.validated(privateHDFactorSource)))
		} catch {
			return fail(error: error)
		}
	}
}

// MARK: - MnemonicDidNotValidateAllAccounts
struct MnemonicDidNotValidateAllAccounts: LocalizedError {
	init() {}
	var errorDescription: String? {
		L10n.ImportMnemonic.failedToValidateAllAccounts
	}
}

extension OverlayWindowClient.Item.HUD {
	fileprivate static let wrongMnemonic = Self(
		text: L10n.ImportMnemonic.wrongMnemonicHUD,
		icon: .init(
			kind: .system("exclamationmark.octagon"),
			foregroundColor: Color.app.red1
		)
	)
}
