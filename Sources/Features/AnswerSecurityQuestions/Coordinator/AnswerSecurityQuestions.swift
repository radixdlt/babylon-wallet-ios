import FeaturePrelude
import MnemonicClient

extension SecurityQuestionsFactorSource {
	public static let defaultQuestions: NonEmpty<OrderedSet<SecurityQuestion>> = {
		.init(
			rawValue: .init(
				uncheckedUniqueElements:
				[
					"Name of Radix DLT's Founder?",
					"Name of Radix DLT's CEO?",
					"Name of Radix DLT's CTO?",
					"Common first name amongst Radix DLT employees from Sweden?",
				].enumerated().map {
					SecurityQuestion(
						id: .init(UInt($0.offset)),
						question: .init(rawValue: $0.element)!
					)
				}
			))!
	}()
}

// MARK: - AnswerSecurityQuestions
public struct AnswerSecurityQuestions: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public enum Step: Sendable, Hashable {
			case flow(AnswerSecurityQuestionsFlow.State)
		}

		public var step: Step

		public init(
			questions: NonEmpty<OrderedSet<SecurityQuestion>>
		) {
			self.step = .flow(.init(questions: questions))
		}

		public init() {
			self.init(questions: SecurityQuestionsFactorSource.defaultQuestions)
		}
	}

	public enum ChildAction: Sendable, Equatable {
		case flow(AnswerSecurityQuestionsFlow.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case done(SecurityQuestionsFactorSource)
	}

	@Dependency(\.mnemonicClient) var mnemonicClient
	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.step, action: /Action.self) {
			EmptyReducer()
				.ifCaseLet(/State.Step.flow, action: /Action.child .. ChildAction.flow) {
					AnswerSecurityQuestionsFlow()
				}
		}

		Reduce(core)
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .flow(.delegate(.answeredAllQuestions(with: answers))):
			do {
				let mnemonic = try mnemonicClient.generate(.twentyFour, .english)
				let factorSource = try SecurityQuestionsFactorSource.from(
					mnemonic: mnemonic,
					answersToQuestions: Set(answers.elements)
				)
				return .send(.delegate(.done(factorSource)))
			} catch {
				fatalError("Failed to create SecurityQuestionsFactorSource from answers, error: \(error)")
			}
		default:
			return .none
		}
	}
}
