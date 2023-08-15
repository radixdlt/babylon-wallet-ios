import AnswerSecurityQuestionsFeature
import FeaturePrelude
import ImportMnemonicFeature
import ManageTrustedContactFactorSourceFeature

// MARK: - ManageSomeFactorSource
public struct ManageSomeFactorSource<FactorSourceOfKind: BaseFactorSourceProtocol>: Sendable, FeatureReducer {
	public enum State: Sendable, Hashable {
		case manageSecurityQuestions(AnswerSecurityQuestionsCoordinator.State)
		case manageTrustedContact(ManageTrustedContactFactorSource.State)
		case manageOffDeviceMnemonics(ImportMnemonic.State)

		public init(kind: FactorSourceKind) {
			switch kind {
			case .device:
				fatalError("It is not possible to add another `device` factor source, bad application logic. Please make sure to disable any 'Add new' button if factor source kind is `device`.")

			case .offDeviceMnemonic:
				self = .manageOffDeviceMnemonics(.init(persistAsMnemonicKind: .intoKeychainAndProfile(.offDevice)))

			case .ledgerHQHardwareWallet:
				fatalError("Should have handled Ledger by use of LedgerHardwareDevicesFeature")

			case .securityQuestions:
				self = .manageSecurityQuestions(.init(purpose: .encrypt))

			case .trustedContact:
				self = .manageTrustedContact(.init(mode: .new))
			}
		}
	}

	public enum ChildAction: Sendable, Equatable {
		case manageSecurityQuestions(AnswerSecurityQuestionsCoordinator.Action)
		case manageTrustedContact(ManageTrustedContactFactorSource.Action)
		case manageOffDeviceMnemonics(ImportMnemonic.Action)
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
	}

	public enum DelegateAction: Sendable, Equatable {
		case done(TaskResult<FactorSourceOfKind>)
	}

	public init() {}
	public var body: some ReducerProtocolOf<Self> {
		Scope(
			state: /ManageSomeFactorSource.State.manageOffDeviceMnemonics,
			action: /Action.child .. ChildAction.manageOffDeviceMnemonics
		) {
			ImportMnemonic()
		}

		Scope(
			state: /ManageSomeFactorSource.State.manageSecurityQuestions,
			action: /Action.child .. ChildAction.manageSecurityQuestions
		) {
			AnswerSecurityQuestionsCoordinator()
		}

		Scope(
			state: /ManageSomeFactorSource.State.manageTrustedContact,
			action: /Action.child .. ChildAction.manageTrustedContact
		) {
			ManageTrustedContactFactorSource()
		}

		Reduce(core)
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .manageOffDeviceMnemonics(.delegate(.savedInProfile(factorSource))):
			return delegateDone(factorSource: factorSource.extract(OffDeviceMnemonicFactorSource.self)!)

		case let .manageTrustedContact(.delegate(.saveFactorSourceResult(.failure(error)))):
			return .send(.delegate(.done(.failure(error))))

		case let .manageTrustedContact(.delegate(.saveFactorSourceResult(.success(trustedContactFactorSource)))):
			return delegateDone(factorSource: trustedContactFactorSource)

		case let .manageSecurityQuestions(.delegate(.done(.success(result)))):
			switch result {
			case .decrypted:
				assertionFailure("Discrepancy! Expected to encrypt security questions creating a new factor source, not decrypt it...")
				return .send(.delegate(.done(.failure(DiscrepancyExpectedToCreateSecurityQuestionsNotDecryptIt()))))
			case let .encrypted(securityQuestionsFactorSource):
				return delegateDone(factorSource: securityQuestionsFactorSource)
			}

		case let .manageSecurityQuestions(.delegate(.done(.failure(error)))):
			return .send(.delegate(.done(.failure(error))))

		default: return .none
		}
	}

	func delegateDone(factorSource: some FactorSourceProtocol) -> EffectTask<Action> {
		if let factorSourceOfKind = factorSource as? FactorSourceOfKind {
			return .send(.delegate(.done(.success(factorSourceOfKind))))
		} else if FactorSourceOfKind.self == FactorSource.self {
			return .send(.delegate(.done(.success(factorSource.embed() as! FactorSourceOfKind))))
		} else {
			let errorMessage = "Critical error, wrong factor source kind produced!"
			loggerGlobal.critical(.init(stringLiteral: errorMessage))
			assertionFailure(errorMessage)
			return .none
		}
	}
}

// MARK: - DiscrepancyExpectedToCreateSecurityQuestionsNotDecryptIt
struct DiscrepancyExpectedToCreateSecurityQuestionsNotDecryptIt: Swift.Error {}
