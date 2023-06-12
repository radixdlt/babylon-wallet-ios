import ComposableArchitecture
import Cryptography
import DesignSystem
import FeaturePrelude
import Prelude

// MARK: - AnswerSecurityQuestionFreeform
public struct AnswerSecurityQuestionFreeform: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public var id: SecurityQuestion.ID { question.id }
		public let question: SecurityQuestion
		public var answer: NonEmptyString? = nil
		public let isLast: Bool
		public init(question: SecurityQuestion, isLast: Bool) {
			self.question = question
			self.isLast = isLast
		}
	}

	public enum ViewAction: Sendable, Hashable {
		case submitAnswer
		case answerChanged(String)
	}

	public enum DelegateAction: Sendable, Hashable {
		case answered(AnswerToSecurityQuestion)
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case let .answerChanged(answer):
			state.answer = NonEmpty(answer)
			return .none

		case .submitAnswer:
			guard let answerString = state.answer else {
				return .none
			}
			let answer = AnswerToSecurityQuestion(
				answer: .from(answerString),
				to: state.question
			)

			return .send(.delegate(.answered(answer)))
		}
	}
}
