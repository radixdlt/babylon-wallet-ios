import ComposableArchitecture
import SwiftUI

// MARK: - NewMainBDFS
/// **B**abylon **D**evice **F**actor **S**ource
public struct NewMainBDFS: Sendable, Hashable {
	public let newMainBDFS: DeviceFactorSource
	public let idsOfAccountsToHide: [Profile.Network.Account.ID]
	public let idsOfPersonasToHide: [Profile.Network.Persona.ID]
	public init(
		newMainBDFS: DeviceFactorSource,
		idsOfAccountsToHide: [Profile.Network.Account.ID],
		idsOfPersonasToHide: [Profile.Network.Persona.ID]
	) {
		self.newMainBDFS = newMainBDFS
		self.idsOfAccountsToHide = idsOfAccountsToHide
		self.idsOfPersonasToHide = idsOfPersonasToHide
	}
}

// MARK: - ImportMnemonicControllingAccounts
public struct ImportMnemonicControllingAccounts: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let entitiesControlledByFactorSource: EntitiesControlledByFactorSource

		public let entities: DisplayEntitiesControlledByMnemonic.State

		@PresentationState
		public var destination: Destinations.State? = nil

		public var isMainBDFS: Bool

		public init(
			entitiesControlledByFactorSource: EntitiesControlledByFactorSource,
			isMainBDFS: Bool
		) {
			self.isMainBDFS = isMainBDFS
			self.entitiesControlledByFactorSource = entitiesControlledByFactorSource
			self.entities = .init(
				accountsForDeviceFactorSource: entitiesControlledByFactorSource,
				mode: .displayAccountListOnly
			)
		}
	}

	public enum InternalAction: Sendable, Equatable {
		case validated(PrivateHDFactorSource)
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared, inputMnemonic, skip
	}

	public enum DelegateAction: Sendable, Equatable {
		case persistedMnemonicInKeychain(FactorSourceID.FromHash)
		case skippedMnemonic(FactorSourceID.FromHash)
		case createdNewMainBDFS(oldSkipped: FactorSourceID.FromHash, NewMainBDFS)
		case failedToSaveInKeychain(FactorSourceID.FromHash)
	}

	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationAction<Destinations.Action>)
		case entities(DisplayEntitiesControlledByMnemonic.Action)
	}

	// MARK: - Destination

	public struct Destinations: Sendable, Reducer {
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
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			return .none
		case .inputMnemonic:
			state.destination = .importMnemonic(.init(
				warning: L10n.RevealSeedPhrase.warning,
				isWordCountFixed: true,
				persistStrategy: nil,
				wordCount: state.entitiesControlledByFactorSource.mnemonicWordCount
			))
			return .none

		case .skip:
			if state.isMainBDFS {
				state.destination = .confirmSkippingBDFS(.init())
				return .none
			} else {
				return .send(.delegate(.skippedMnemonic(state.entitiesControlledByFactorSource.factorSourceID)))
			}
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .destination(.presented(
			.importMnemonic(.delegate(delegateAction))
		)):
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

		case .destination(.presented(.confirmSkippingBDFS(.delegate(.cancel)))):
			state.destination = nil
			return .none

		case .destination(.presented(.confirmSkippingBDFS(.delegate(.confirmed)))):
			loggerGlobal.notice("Skipping BDFS! Generating a new one and hiding affected accounts/personas.")
			return .run { [entitiesControlledByFactorSource = state.entitiesControlledByFactorSource] send in
				loggerGlobal.info("Generating mnemonic for new main BDFS")
				let newBDFS = try await factorSourcesClient.createNewMainBDFS()
				let accountsToHide = entitiesControlledByFactorSource.accounts
				let personasToHide = entitiesControlledByFactorSource.personas
				loggerGlobal.info("Delegating done with creating new BDFS (skipped old)")
				await send(.delegate(.createdNewMainBDFS(
					oldSkipped: entitiesControlledByFactorSource.factorSourceID,
					.init(
						newMainBDFS: newBDFS.factorSource,
						idsOfAccountsToHide: accountsToHide.map(\.id),
						idsOfPersonasToHide: personasToHide.map(\.id)
					)
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

// extension AlertState<ImportMnemonicControllingAccounts.Destinations.Action.ConfirmSkipBDFS> {
// 	static func confirmSkippingBDFS() -> AlertState {
// 		AlertState {
// 			TextState("Sure?")
// 		} actions: {
// 			ButtonState(role: .destructive, action: .confirmTapped) {
// 				TextState(L10n.Common.remove)
// 			}
// 			ButtonState(role: .cancel, action: .cancelTapped) {
// 				TextState(L10n.Common.cancel)
// 			}
// 		} message: {
// 			TextState("Sure?!")
// 		}
// 	}
// }
