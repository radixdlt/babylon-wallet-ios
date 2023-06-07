import AnswerSecurityQuestionsFeature
import FeaturePrelude

// MARK: - SimpleNewPhoneConfirmer
public struct SimpleNewPhoneConfirmer: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var answerSecurityQuestions: AnswerSecurityQuestions.State
		public init(
			questions: NonEmpty<OrderedSet<SecurityQuestion>> = SecurityQuestionsFactorSource.defaultQuestions
		) {
			self.answerSecurityQuestions = .init(purpose: .encrypt(questions))
		}
	}

	public enum ChildAction: Sendable, Equatable {
		case answerSecurityQuestions(AnswerSecurityQuestions.Action)
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .none
		}
	}
}
