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
		public let keyDerivationScheme: SecurityQuestionsFactorSource.KeyDerivationScheme
		var root: Path.State
		var path: StackState<Path.State> = .init()

		public init(purpose: Purpose) {
			self.purpose = purpose
			switch purpose {
			case .encrypt:
				self.questions = []
				self.root = .chooseQuestions(.init())
				self.keyDerivationScheme = .default

			case let .decrypt(factorSource):
				let sealedMnemonic = factorSource.sealedMnemonic
				let questions = sealedMnemonic.securityQuestions
				let kdfScheme = sealedMnemonic.keyDerivationScheme
				self.keyDerivationScheme = kdfScheme
				self.questions = questions.rawValue
				self.root = .answerQuestion(.init(
					keyDerivationScheme: kdfScheme,
					question: questions.first,
					isLast: questions.count == 1
				))
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

	public struct Path: Sendable, Reducer {
		public enum State: Sendable, Hashable {
			case chooseQuestions(ChooseQuestions.State)
			case answerQuestion(AnswerSecurityQuestionFreeform.State)

			public var answerToQuestion: AnswerToSecurityQuestion? {
				guard case let .answerQuestion(freeformState) = self else { return nil }
				return freeformState.answerToQuestion
			}

			public var rawAnswerToQuestion: AbstractAnswerToSecurityQuestion<NonEmptyString>? {
				guard case let .answerQuestion(freeformState) = self else { return nil }
				return freeformState.rawAnswerToQuestion
			}
		}

		public enum Action: Sendable, Equatable {
			case chooseQuestions(ChooseQuestions.Action)
			case answerQuestion(AnswerSecurityQuestionFreeform.Action)
		}

		public var body: some ReducerOf<Self> {
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

	public var body: some ReducerOf<Self> {
		Scope(state: \.root, action: /Action.child .. ChildAction.root) {
			Path()
		}

		Reduce(core)
			.forEach(\.path, action: /Action.child .. ChildAction.path) {
				Path()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .closeButtonTapped:
			return dismissEffect(for: state, errorKind: .rejectedByUser)
		case .backButtonTapped:
			return goBackEffect(for: &state)
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case
			let .root(.chooseQuestions(.delegate(.choseQuestions(chosenQuestions)))):
			state.questions = chosenQuestions.rawValue
			return answerNextQuestion(&state)

		case
			.root(.answerQuestion(.delegate(.answered))),
			.path(.element(id: _, action: .answerQuestion(.delegate(.answered)))):

			return answerNextQuestion(&state)

		default: return .none
		}
	}

	func answerNextQuestion(_ state: inout State) -> Effect<Action> {
		let answers = ([state.root] + state.path).compactMap(\.answerToQuestion)
		let unansweredQuestions = state.questions.filter { question in
			!answers.contains(where: { $0.question == question })
		}

		if let nextQuestion = unansweredQuestions.first {
			state.path.append(.answerQuestion(.init(
				keyDerivationScheme: state.keyDerivationScheme,
				question: nextQuestion,
				isLast: unansweredQuestions.count == 1
			)))

			return .none
		} else {
			let answers: NonEmpty<OrderedSet<AnswerToSecurityQuestion>> = NonEmpty(
				rawValue: OrderedSet(
					uncheckedUniqueElements: answers
				)
			)!
			precondition(answers.count == state.questions.count)

			return .run { [purpose = state.purpose] send in
				let taskResult = await TaskResult { () -> State.Purpose.AnswersResult in
					switch purpose {
					case let .decrypt(factorSource):
						precondition(factorSource.sealedMnemonic.securityQuestions.elements == answers.elements.map(\.question))

						let mnemonic = try factorSource.decrypt(answersToQuestions: answers)

						return .decrypted(mnemonic)

					case .encrypt:
						let mnemonic = try mnemonicClient.generate(.twentyFour, .english)
						loggerGlobal.debug("mnemonic: \(mnemonic.phrase)")

						let securityQuestionsFactorSource = try SecurityQuestionsFactorSource.from(
							mnemonic: mnemonic,
							answersToQuestions: answers
						)

						try await factorSourcesClient.saveFactorSource(securityQuestionsFactorSource.embed())

						return .encrypted(securityQuestionsFactorSource)
					}
				}
				await send(.delegate(.done(taskResult)))
			}
		}
	}

	func goBackEffect(for state: inout State) -> Effect<Action> {
		state.path.removeLast()
		return .none
	}

	func dismissEffect(
		for state: State,
		errorKind: Error
	) -> Effect<Action> {
		.send(.delegate(.done(.failure(errorKind))))
	}

	public enum Error: String, Swift.Error {
		case rejectedByUser
	}
}
