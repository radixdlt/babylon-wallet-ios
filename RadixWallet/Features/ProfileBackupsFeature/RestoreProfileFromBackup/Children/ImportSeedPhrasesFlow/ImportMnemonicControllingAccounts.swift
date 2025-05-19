import ComposableArchitecture
import SwiftUI

// MARK: - ImportMnemonicControllingAccounts
struct ImportMnemonicControllingAccounts: Sendable, FeatureReducer {
	struct State: Sendable, Hashable, Identifiable {
		var id: EntitiesControlledByFactorSource.ID {
			entitiesControlledByFactorSource.id
		}

		let entitiesControlledByFactorSource: EntitiesControlledByFactorSource

		let entities: DisplayEntitiesControlledByMnemonic.State

		@PresentationState
		var destination: Destination.State? = nil

		var isMainBDFS: Bool

		init(
			entitiesControlledByFactorSource ents: EntitiesControlledByFactorSource,
			isMainBDFS: Bool
		) {
			self.isMainBDFS = isMainBDFS
			self.entitiesControlledByFactorSource = ents

			let accounts: IdentifiedArrayOf<Account>
			let hiddenAccountsCount: Int
			switch (ents.babylonAccounts.isEmpty, ents.olympiaAccounts.isEmpty) {
			case (false, _):
				// We prefer Babylon, always.
				accounts = ents.babylonAccounts
				hiddenAccountsCount = ents.babylonAccountsHidden.count
			case (true, false):
				accounts = ents.olympiaAccounts
				hiddenAccountsCount = ents.olympiaAccountsHidden.count
			case (true, true):
				// no accounts... still possible! i.e. Profile -> Create HARDWARE Account ->
				// delete passcode -> import missing Mnemonic, which... does not control any
				// accounts
				accounts = []
				hiddenAccountsCount = 0
			}

			self.entities = .init(
				id: .mixedCurves(
					ents.factorSourceID
				),
				isMnemonicMarkedAsBackedUp: ents.isMnemonicMarkedAsBackedUp,
				isMnemonicPresentInKeychain: ents.isMnemonicPresentInKeychain,
				accounts: accounts,
				hiddenAccountsCount: hiddenAccountsCount,
				personasCount: ents.personas.count,
				mode: .displayAccountListOnly
			)
		}
	}

	enum InternalAction: Sendable, Equatable {
		case validated(PrivateHierarchicalDeterministicFactorSource)
	}

	enum ViewAction: Sendable, Equatable {
		case appeared
		case inputMnemonicButtonTapped
		case skipButtonTapped
	}

	enum DelegateAction: Sendable, Equatable {
		case persistedMnemonicInKeychain(FactorSourceIDFromHash)
		case skippedMnemonic(FactorSourceIDFromHash)
		case skippedMainBDFS(FactorSourceIDFromHash)
		case failedToSaveInKeychain(FactorSourceIDFromHash)
	}

	enum ChildAction: Sendable, Equatable {
		case entities(DisplayEntitiesControlledByMnemonic.Action)
	}

	// MARK: - Destination

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case importMnemonic(ImportMnemonic.State)
			case confirmSkippingBDFS(ConfirmSkippingBDFS.State)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case importMnemonic(ImportMnemonic.Action)
			/// **B**abylon **D**evice **F**actor **S**ource
			case confirmSkippingBDFS(ConfirmSkippingBDFS.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.importMnemonic, action: \.importMnemonic) {
				ImportMnemonic()
			}
			Scope(state: \.confirmSkippingBDFS, action: \.confirmSkippingBDFS) {
				ConfirmSkippingBDFS()
			}
		}
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.secureStorageClient) var secureStorageClient
	@Dependency(\.overlayWindowClient) var overlayWindowClient
	@Dependency(\.userDefaults) var userDefaults
	@Dependency(\.factorSourcesClient) var factorSourcesClient

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
			return .none

		case .inputMnemonicButtonTapped:
			state.destination = .importMnemonic(.init(
				warning: L10n.RevealSeedPhrase.warning,
				showCloseButton: true,
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

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case let .importMnemonic(.delegate(delegateAction)):
			switch delegateAction {
			case let .notPersisted(mnemonicWithPassphrase):
				let factorSourceID = FactorSourceIDFromHash(kind: .device, mnemonicWithPassphrase: mnemonicWithPassphrase)

				guard factorSourceID == state.entitiesControlledByFactorSource.factorSourceID else {
					overlayWindowClient.scheduleHUD(.wrongMnemonic)
					return .none
				}

				return validate(
					mnemonicWithPassphrase: mnemonicWithPassphrase,
					accounts: state.entitiesControlledByFactorSource.accounts,
					factorSource: state.entitiesControlledByFactorSource.deviceFactorSource
				)

			case .persistedMnemonicInKeychainOnly, .persistedNewFactorSourceInProfile:
				preconditionFailure("Incorrect implementation")
			}

		case .confirmSkippingBDFS(.delegate(.cancel)):
			state.destination = nil
			return .none

		case .confirmSkippingBDFS(.delegate(.confirmed)):
			state.destination = nil
			return .send(.delegate(.skippedMainBDFS(state.entitiesControlledByFactorSource.factorSourceID)))

		default:
			return .none
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
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
		accounts: [Account],
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

			let privateHDFactorSource = PrivateHierarchicalDeterministicFactorSource(
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
	fileprivate static let wrongMnemonic = Self.failure(text: L10n.ImportMnemonic.wrongMnemonicHUD)
}
