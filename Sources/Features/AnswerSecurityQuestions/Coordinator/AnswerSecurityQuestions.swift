import Cryptography
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

		public enum Purpose: Sendable, Hashable {
			case decrypt(SecurityQuestionsFactorSource)
			case encrypt(NonEmpty<OrderedSet<SecurityQuestion>>)

			public enum AnswersResult: Sendable, Hashable {
				case decrypted(Mnemonic)
				case encrypted(SecurityQuestionsFactorSource)
			}
		}

		public var step: Step
		public let purpose: Purpose

		public init(
			purpose: Purpose
		) {
			self.purpose = purpose
			switch purpose {
			case let .decrypt(factorSource):
				self.step = .flow(.init(questions: factorSource.sealedMnemonic.securityQuestions))
			case let .encrypt(questions):
				self.step = .flow(.init(questions: questions))
			}
		}
	}

	public enum ChildAction: Sendable, Equatable {
		case flow(AnswerSecurityQuestionsFlow.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case done(TaskResult<AnswerSecurityQuestions.State.Purpose.AnswersResult>)
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
			return .task { [purpose = state.purpose] in

				let taskResult = await TaskResult {
					switch purpose {
					case let .decrypt(factorSource):
						precondition(factorSource.sealedMnemonic.securityQuestions.elements == answers.elements.map(\.question))

						let mnemonic = try factorSource.decrypt(answersToQuestions: answers)

						return AnswerSecurityQuestions.State.Purpose.AnswersResult.decrypted(mnemonic)
					case .encrypt:
						let mnemonic = try mnemonicClient.generate(.twentyFour, .english)

						let factorSource = try SecurityQuestionsFactorSource.from(
							mnemonic: mnemonic,
							answersToQuestions: answers
						)

						return AnswerSecurityQuestions.State.Purpose.AnswersResult.encrypted(factorSource)
					}
				}
				return .delegate(.done(taskResult))
			}
		default:
			return .none
		}
	}
}

// MARK: - ForceErrorToTestFailure
struct ForceErrorToTestFailure: Swift.Error, CustomStringConvertible {
	let description = "Forced Error testing failure"
}
