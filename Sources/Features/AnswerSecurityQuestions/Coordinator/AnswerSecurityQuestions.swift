import FeaturePrelude
import MnemonicClient

extension SecurityQuestionsFactorSource {
	public static let defaultQuestions: IdentifiedArrayOf<SecurityQuestion> = {
		.init(uniqueElements: [
			.init(id: 0, question: "1+1"),
			.init(id: 1, question: "2+2"),
			.init(id: 2, question: "3+3"),
			.init(id: 3, question: "5+5"),
		])
	}()
}

// MARK: - AnswerSecurityQuestions
public struct AnswerSecurityQuestions: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var answersToQuestions: Set<AnswerToSecurityQuestion> = []
		public let questions: IdentifiedArrayOf<SecurityQuestion>
		public init(
			questions: IdentifiedArrayOf<SecurityQuestion>
		) {
			self.questions = questions
		}

		public init() {
			self.init(questions: SecurityQuestionsFactorSource.defaultQuestions)
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case done
	}

	public enum DelegateAction: Sendable, Equatable {
		case done(SecurityQuestionsFactorSource)
	}

	@Dependency(\.mnemonicClient) var mnemonicClient
	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .done:

			do {
				let mnemonic = try mnemonicClient.generate(.twentyFour, .english)
				let factorSource = try SecurityQuestionsFactorSource.from(
					mnemonic: mnemonic,
					answersToQuestions: state.answersToQuestions
				)
				return .send(.delegate(.done(factorSource)))
			} catch {
				fatalError()
			}
		}
	}
}
