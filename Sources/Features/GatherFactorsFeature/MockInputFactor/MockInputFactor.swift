import FeaturePrelude

// MARK: - QuestionAndAnswer
public struct QuestionAndAnswer: Sendable, Hashable {
	public let question: String
	public let expectedAnswer: String
}

// MARK: - QuestionsProtocol
public protocol QuestionsProtocol: Sendable, Hashable {
	var questionAndAnswers: OrderedSet<QuestionAndAnswer> { get }
}

// MARK: - MathQuestions
public struct MathQuestions: QuestionsProtocol {
	public let questionAndAnswers: OrderedSet<QuestionAndAnswer>
}

public typealias FactorFromMathQuestions = FactorFromQuestions<MathQuestions>

// MARK: - FactorFromQuestions
public struct FactorFromQuestions<QuestionsAndAnswers: QuestionsProtocol>: ReducerProtocol {
	public init() {}
	public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		.none
	}

	public struct State: Sendable, Equatable {
		public let questionsAndAnswers: QuestionsAndAnswers
		public init(questionsAndAnswers: QuestionsAndAnswers) {
			self.questionsAndAnswers = questionsAndAnswers
		}
	}

	public enum Action: Sendable, Equatable {
		case noop
	}

	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<FactorFromQuestions<QuestionsAndAnswers>>

		public init(store: StoreOf<FactorFromQuestions<QuestionsAndAnswers>>) {
			self.store = store
		}

		//        struct ViewState: Equatable {
		//            init(state: FactorFromQuestions.State<QuestionsAndAnswers>) {
		//                // TODO: implement
		//            }
		//        }
		public var body: some SwiftUI.View {
			//            WithViewStore(
			//                store,
			//                observe: ViewState.init(state:),
			//                send: { .view($0) }
			//            ) { viewStore in
			//                // TODO: implement
			//                Text("Implement: FactorFromMathEquationFeature")
			//                    .background(Color.yellow)
			//                    .foregroundColor(.red)
			//            }
			Text("IMPL ME")
		}
	}
}
