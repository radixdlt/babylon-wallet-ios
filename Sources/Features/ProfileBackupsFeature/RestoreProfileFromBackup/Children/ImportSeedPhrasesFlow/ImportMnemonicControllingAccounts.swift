import DisplayEntitiesControlledByMnemonicFeature
import FeaturePrelude
import ImportMnemonicFeature
import OverlayWindowClient

// MARK: - ImportMnemonicControllingAccounts
public struct ImportMnemonicControllingAccounts: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let entitiesControlledByFactorSource: EntitiesControlledByFactorSource

		public let entities: DisplayEntitiesControlledByMnemonic.State

		@PresentationState
		public var destination: Destinations.State? = nil

		public init(entitiesControlledByFactorSource: EntitiesControlledByFactorSource) {
			self.entitiesControlledByFactorSource = entitiesControlledByFactorSource
			self.entities = .init(accountsForDeviceFactorSource: entitiesControlledByFactorSource, displayRevealMnemonicLink: false)
		}
	}

	public enum InternalAction: Sendable, Equatable {
		case validated(PrivateHDFactorSource)
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared, inputMnemonic, skip
	}

	public enum DelegateAction: Sendable, Equatable {
		case persistedMnemonicInKeychain(FactorSource.ID)
		case skippedMnemonic(FactorSourceID.FromHash)
	}

	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationAction<Destinations.Action>)
		case entities(DisplayEntitiesControlledByMnemonic.Action)
	}

	// MARK: - Destination

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case importMnemonic(ImportMnemonic.State)
		}

		public enum Action: Sendable, Equatable {
			case importMnemonic(ImportMnemonic.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.importMnemonic, action: /Action.importMnemonic) {
				ImportMnemonic()
			}
		}
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.secureStorageClient) var secureStorageClient
	@Dependency(\.overlayWindowClient) var overlayWindowClient

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .none
		case .inputMnemonic:
			state.destination = .importMnemonic(.init(
				// FIXME: Strings
				warning: "For your safety, make sure no one is looking at your screen. Never give your seed phrase to anyone for any reason.",
				isWordCountFixed: true,
				persistStrategy: nil,
				wordCount: state.entitiesControlledByFactorSource.mnemonicWordCount
			))
			return .none

		case .skip:
			precondition(state.entitiesControlledByFactorSource.isSkippable)
			loggerGlobal.feature("TODO skip me")
			return .send(.delegate(.skippedMnemonic(state.entitiesControlledByFactorSource.factorSourceID)))
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
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
					// FIXME: Strings
					overlayWindowClient.scheduleHUD(.init(
						text: "Wrong mnemmonic",
						icon: .init(
							kind: .system("exclamationmark.octagon"),
							foregroundColor: Color.app.red1
						)
					)
					)
					return .none
				}

				return validate(
					mnemonicWithPassphrase: mnemonicWithPassphrase,
					accounts: state.entitiesControlledByFactorSource.accounts,
					factorSource: state.entitiesControlledByFactorSource.deviceFactorSource
				)

			case .persistedMnemonicInKeychainOnly, .doneViewing, .persistedNewFactorSourceInProfile:
				preconditionFailure("Incorrect implementation")
				return .none
			}

		default:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .validated(privateHDFactorSource):
			return .run { _ in
				try await secureStorageClient.saveMnemonicForFactorSource(
					privateHDFactorSource
				)
			} catch: { _, _ in
				fatalError()
			}

			return .send(.delegate(.persistedMnemonicInKeychain(state.entitiesControlledByFactorSource.factorSourceID.embed())))
		}
	}

	private func validate(
		mnemonicWithPassphrase: MnemonicWithPassphrase,
		accounts: [Profile.Network.Account],
		factorSource: DeviceFactorSource
	) -> EffectTask<Action> {
		func fail(error: Swift.Error?) -> EffectTask<Action> {
			loggerGlobal.error("Failed to validate all accounts against mnemonic, underlying error: \(String(describing: error))")
			errorQueue.schedule(MnemonicDidNotValidateAllAccounts())
			return .none
		}
		do {
			guard try mnemonicWithPassphrase.validatePublicKeysOf(accounts: accounts) else {
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
		// FIXME: Strings
		"Invalid seed phrase"
	}
}
