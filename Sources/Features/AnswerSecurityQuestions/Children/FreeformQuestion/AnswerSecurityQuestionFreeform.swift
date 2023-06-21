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

		public var answerToQuestion: AnswerToSecurityQuestion?
		public var rawAnswerToQuestion: AbstractAnswerToSecurityQuestion<NonEmptyString>? {
			guard let nonEmptyAnswer = answer else {
				return nil
			}
			return .init(answer: nonEmptyAnswer, to: question)
		}

		public init(
			question: SecurityQuestion,
			isLast: Bool
		) {
			self.question = question
			self.isLast = isLast
		}
	}

	public enum ViewAction: Sendable, Hashable {
		case submitAnswer(SecurityQuestionAnswerAsEntropy)
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

		case let .submitAnswer(answer):
			let answerToQuestion = AnswerToSecurityQuestion(
				answer: answer,
				to: state.question
			)
			state.answerToQuestion = answerToQuestion
			return .send(.delegate(.answered(answerToQuestion)))
		}
	}
}
