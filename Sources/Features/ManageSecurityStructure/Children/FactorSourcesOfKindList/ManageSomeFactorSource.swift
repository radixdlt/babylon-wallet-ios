import AnswerSecurityQuestionsFeature
import FeaturePrelude
import ManageTrustedContactFactorSourceFeature

// MARK: - ManageSomeFactorSource
public struct ManageSomeFactorSource<FactorSourceOfKind: FactorSourceProtocol>: Sendable, FeatureReducer {
	public enum State: Sendable, Hashable {
		case manageSecurityQuestions(AnswerSecurityQuestionsCoordinator.State)
		case manageTrustedContact(ManageTrustedContactFactorSource.State)
		public init() {
			switch FactorSourceOfKind.kind {
			case .device, .ledgerHQHardwareWallet, .offDeviceMnemonic: fatalError("Unsupported")
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
		case let .manageSecurityQuestions(.delegate(.done(.failure(error)))):
			return .send(.delegate(.done(.failure(error))))
		default: return .none
		}
	}
}
