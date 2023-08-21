import FeaturePrelude
import ImportMnemonicFeature

// MARK: - ImportMnemonicControllingAccounts
public struct ImportMnemonicControllingAccounts: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let mnemonicToImport: MnemonicToImport

		@PresentationState
		public var destination: Destinations.State? = nil

		public init(mnemonicToImport: MnemonicToImport) {
			self.mnemonicToImport = mnemonicToImport
		}
	}

	public enum InternalAction: Sendable, Equatable {
		case validated
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared, inputMnemonic
	}

	public enum DelegateAction: Sendable, Equatable {
		case persistedMnemonicInKeychain(FactorSource.ID)
	}

	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationAction<Destinations.Action>)
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
				isWordCountFixed: true,
				persistStrategy: .intoKeychainOnly,
				mnemonicForFactorSourceKind: state.mnemonicToImport.mnemonicWordCount == .twelve ? .onDevice(.olympia) : .onDevice(.babylon)
			))
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .destination(.presented(
			.importMnemonic(.delegate(.persistedMnemonicInKeychainOnly(mnemonicWithPassphrase, factorSourceID)))
		)):
			guard factorSourceID == state.mnemonicToImport.factorSourceID else {
				fatalError("factor source ID mismatch")
			}
			return validate(
				mnemonic: mnemonicWithPassphrase, accounts: state.mnemonicToImport.controllingAccounts
			)

//            state.mnemonicsLeftToImport.removeAll(where: { $0.factorSourceID == factorSourceID })
//            return nextMnemonicIfNeeded(state: &state)

		default:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case .validated:
			return .send(.delegate(.persistedMnemonicInKeychain(state.mnemonicToImport.factorSourceID.embed())))
		}
	}

	private func validate(
		mnemonic: MnemonicWithPassphrase,
		accounts: [Profile.Network.Account]
	) -> EffectTask<Action> {
		fatalError()
		return .send(.internal(.validated))
	}
}
