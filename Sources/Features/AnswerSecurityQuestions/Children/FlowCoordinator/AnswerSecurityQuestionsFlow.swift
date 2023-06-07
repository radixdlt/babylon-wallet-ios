import ComposableArchitecture
import Cryptography
import DesignSystem
import FeaturePrelude
import Prelude

// MARK: - AnswerSecurityQuestionsFlow
public struct AnswerSecurityQuestionsFlow: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let questions: NonEmpty<OrderedSet<SecurityQuestion>>
		public var answers: OrderedDictionary<SecurityQuestion.ID, AnswerToSecurityQuestion> = [:]

		var root: Path.State?

		var path: StackState<Path.State> = []

		init(
			questions: NonEmpty<OrderedSet<SecurityQuestion>>
		) {
			self.questions = questions
			self.root = .freeform(.init(question: questions.first, isLast: questions.count == 1))
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case closeButtonTapped
		case backButtonTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case askQuestionFreeform(SecurityQuestion)
	}

	public enum ChildAction: Sendable, Equatable {
		case root(Path.Action)
		case path(StackAction<Path.Action>)
	}

	public enum DelegateAction: Sendable, Hashable {
		case dismiss(errorKind: Error, message: String?)
		case answeredAllQuestions(
			with: NonEmpty<OrderedSet<AnswerToSecurityQuestion>>
		)
	}

	public struct Path: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case freeform(AnswerSecurityQuestionsFreeform.State)
		}

		public enum Action: Sendable, Equatable {
			case freeform(AnswerSecurityQuestionsFreeform.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.freeform, action: /Action.freeform) {
				AnswerSecurityQuestionsFreeform()
			}
		}
	}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.root, action: /Action.child .. ChildAction.root) {
				Path()
			}
			.forEach(\.path, action: /Action.child .. ChildAction.path) {
				Path()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .closeButtonTapped:
			return dismissEffect(for: state, errorKind: .rejectedByUser, message: nil)
		case .backButtonTapped:
			return goBackEffect(for: &state)
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
//		case
//			let .root(.relay(item, .freeform(.delegate(.answered(answer, question))))),
//			let .path(.element(_, .relay(item, .freeform(.delegate(.answered(answer, question)))))):
		case
			let .root(.freeform(.delegate(.answered(answerToQuestion)))),
			let .path(.element(id: _, action: .freeform(.delegate(.answered(answerToQuestion))))):
			state.answers[answerToQuestion.question.id] = answerToQuestion
			return continueEffect(for: &state)

		default: return .none
		}
	}

	func continueEffect(for state: inout State) -> EffectTask<Action> {
		let unansweredQuestions = state.questions.filter { state.answers[$0.id] == nil }
		if let nextQuestion = unansweredQuestions.first {
			let pathState = Path.State.freeform(
				.init(
					question: nextQuestion,
					isLast: unansweredQuestions.count == 1
				)
			)
			if state.root == nil {
				state.root = pathState
			} else {
				state.path.append(pathState)
			}
			return .none
		} else {
			let answers: NonEmpty<OrderedSet<AnswerToSecurityQuestion>> = NonEmpty(
				rawValue: OrderedSet(
					uncheckedUniqueElements: state.answers.values.map { $0 }
				)
			)!
			return .run { send in
				await send(.delegate(.answeredAllQuestions(with: answers)))
			}
		}
	}

	func goBackEffect(for state: inout State) -> EffectTask<Action> {
		state.answers.removeLast()
		state.path.removeLast()
		return .none
	}

	func dismissEffect(
		for state: State,
		errorKind: Error,
		message: String?
	) -> EffectTask<Action> {
		.send(.delegate(.dismiss(
			errorKind: errorKind,
			message: message
		)))
	}

	public enum Error: String, Swift.Error {
		case rejectedByUser
	}
}
