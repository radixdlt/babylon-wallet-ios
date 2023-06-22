import Cryptography
import FactorSourcesClient
import FeaturePrelude
import MnemonicClient

// MARK: - AnswerSecurityQuestionsCoordinator
public struct AnswerSecurityQuestionsCoordinator: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public enum Purpose: Sendable, Hashable {
			case decrypt(SecurityQuestionsFactorSource)
			case encrypt

			public enum AnswersResult: Sendable, Hashable {
				case decrypted(Mnemonic)
				case encrypted(SecurityQuestionsFactorSource)
			}
		}

		public var questions: OrderedSet<SecurityQuestion>

		public let purpose: Purpose
		var root: Path.State
		var path: StackState<Path.State> = .init()

		public init(purpose: Purpose) {
			self.purpose = purpose
			switch purpose {
			case .encrypt:
				self.questions = []
				self.root = .chooseQuestions(.init())

			case let .decrypt(factorSource):
				let questions = factorSource.sealedMnemonic.securityQuestions
				self.questions = questions.rawValue
				self.root = .answerQuestion(.init(question: questions.first, isLast: questions.count == 1))
			}
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case closeButtonTapped
		case backButtonTapped
	}

	public enum DelegateAction: Sendable, Hashable {
		case done(TaskResult<State.Purpose.AnswersResult>)
	}

	public enum InternalAction: Sendable, Equatable {
		case askQuestionFreeform(SecurityQuestion)
	}

	public enum ChildAction: Sendable, Equatable {
		case root(Path.Action)
		case path(StackActionOf<Path>)
	}

	public struct Path: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case chooseQuestions(ChooseQuestions.State)
			case answerQuestion(AnswerSecurityQuestionFreeform.State)

			public var answerToQuestion: AnswerToSecurityQuestion? {
				guard case let .answerQuestion(freeformState) = self else { return nil }
				return freeformState.answerToQuestion
			}
		}

		public enum Action: Sendable, Equatable {
			case chooseQuestions(ChooseQuestions.Action)
			case answerQuestion(AnswerSecurityQuestionFreeform.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.chooseQuestions, action: /Action.chooseQuestions) {
				ChooseQuestions()
			}
			Scope(state: /State.answerQuestion, action: /Action.answerQuestion) {
				AnswerSecurityQuestionFreeform()
			}
		}
	}

	@Dependency(\.mnemonicClient) var mnemonicClient
	@Dependency(\.factorSourcesClient) var factorSourcesClient

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.root, action: /Action.child .. ChildAction.root) {
			Path()
		}

		Reduce(core)
			.forEach(\.path, action: /Action.child .. ChildAction.path) {
				Path()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .closeButtonTapped:
			return dismissEffect(for: state, errorKind: .rejectedByUser)
		case .backButtonTapped:
			return goBackEffect(for: &state)
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case
			let .root(.chooseQuestions(.delegate(.choseQuestions(chosenQuestions)))):
			state.questions = chosenQuestions.rawValue
			state.path.append(.answerQuestion(.init(question: chosenQuestions.first, isLast: chosenQuestions.count == 1)))
			return .none

		case
			.root(.answerQuestion(.delegate(.answered))),
			.path(.element(id: _, action: .answerQuestion(.delegate(.answered)))):

			return continueEffect(for: &state)

		default: return .none
		}
	}

	func continueEffect(for state: inout State) -> EffectTask<Action> {
		let answers = ([state.root] + state.path).compactMap(\.answerToQuestion)
		let unansweredQuestions = state.questions.filter { question in
			!answers.contains(where: { $0.question == question })
		}

		if let nextQuestion = unansweredQuestions.first {
			let pathState = Path.State.answerQuestion(
				.init(
					question: nextQuestion,
					isLast: unansweredQuestions.count == 1
				)
			)

			state.path.append(pathState)

			return .none
		} else {
			let answers: NonEmpty<OrderedSet<AnswerToSecurityQuestion>> = NonEmpty(
				rawValue: OrderedSet(
					uncheckedUniqueElements: answers
				)
			)!
			precondition(answers.count == state.questions.count)
			return .task { [purpose = state.purpose] in

				let taskResult = await TaskResult {
					switch purpose {
					case let .decrypt(factorSource):
						precondition(factorSource.sealedMnemonic.securityQuestions.elements == answers.elements.map(\.question))

						let mnemonic = try factorSource.decrypt(answersToQuestions: answers)

						return State.Purpose.AnswersResult.decrypted(mnemonic)

					case .encrypt:
						let mnemonic = try mnemonicClient.generate(.twentyFour, .english)
						loggerGlobal.debug("mnemonic: \(mnemonic.phrase)")

						let factorSource = try SecurityQuestionsFactorSource.from(
							mnemonic: mnemonic,
							answersToQuestions: answers
						)

						try await factorSourcesClient.saveFactorSource(factorSource.embed())

						return State.Purpose.AnswersResult.encrypted(factorSource)
					}
				}
				return .delegate(.done(taskResult))
			}
		}
	}

	func goBackEffect(for state: inout State) -> EffectTask<Action> {
		state.path.removeLast()
		return .none
	}

	func dismissEffect(
		for state: State,
		errorKind: Error
	) -> EffectTask<Action> {
		.send(.delegate(.done(.failure(errorKind))))
	}

	public enum Error: String, Swift.Error {
		case rejectedByUser
	}
}
