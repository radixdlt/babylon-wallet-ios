import AnswerSecurityQuestionsFeature
import FeaturePrelude

// MARK: - SimpleNewPhoneConfirmer
public struct SimpleNewPhoneConfirmer: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		@PresentationState
		public var answerSecurityQuestions: AnswerSecurityQuestionsCoordinator.State?

		public init(
			questions: NonEmpty<OrderedSet<SecurityQuestion>> = SecurityQuestionsFactorSource.defaultQuestions
		) {
			self.answerSecurityQuestions = .init(purpose: .encrypt(questions))
		}
	}

	public enum ChildAction: Sendable, Equatable {
		case answerSecurityQuestions(PresentationAction<AnswerSecurityQuestionsCoordinator.Action>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case createdFactorSource(SecurityQuestionsFactorSource)
	}

	@Dependency(\.dismiss) var dismiss
	@Dependency(\.errorQueue) var errorQueue
	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$answerSecurityQuestions, action: /Action.child .. ChildAction.answerSecurityQuestions) {
				AnswerSecurityQuestionsCoordinator()
			}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .answerSecurityQuestions(.presented(.delegate(.done(.success(.encrypted(factorSource)))))):
			state.answerSecurityQuestions = nil
			return .run { send in
				await send(.delegate(.createdFactorSource(factorSource)))
				await dismiss()
			}

		case .answerSecurityQuestions(.presented(.delegate(.done(.success(.decrypted))))):
			let errorMessage = "Unexpecte delegate action, expected to have created a factor source, not decrypt one."
			loggerGlobal.error(.init(stringLiteral: errorMessage))
			assertionFailure(errorMessage)
			return .none

		case let .answerSecurityQuestions(.presented(.delegate(.done(.failure(error))))):
			if let _error = error as? AnswerSecurityQuestionsCoordinator.Error, _error == .rejectedByUser {
				state.answerSecurityQuestions = nil
				return .run { _ in
					await dismiss()
				}
			}
			let errorMessage = "Failed to create factor source from answers, error: \(error)"
			loggerGlobal.error(.init(stringLiteral: errorMessage))
			errorQueue.schedule(error)
			return .none

		default:
			return .none
		}
	}
}
