import FeaturePrelude

extension SecurityQuestionsFactorSource {
	public static let defaultQuestions: NonEmpty<OrderedSet<SecurityQuestion>> = {
		.init(
			rawValue: .init(
				uncheckedUniqueElements:
				[
					"What's the first name of RDX Works Founder",
					"What's the first name of RDX Works CEO",
					"What's the first name of RDX Works CTO",
					"What's the first name of RDX Works CPO",
					"What's a common first name amongst Swedish RDX Works employees",
					"What's the name of the first version of the Radix network (launch 2022)",
					"What's the name of the second version of the Radix network (launch 2022)",
					"What's the name of the third version of the Radix network (launch 2023)",
					"What's the name of the fourth version of the Radix network (launch 2024)",
				].enumerated().map {
					SecurityQuestion(
						id: .init(UInt($0.offset)),
						question: .init(rawValue: $0.element)!
					)
				}
			))!
	}()
}

// MARK: - ChooseQuestions
public struct ChooseQuestions: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let availableQuestions: NonEmpty<OrderedSet<SecurityQuestion>>

		public let selectionRequirement: SelectionRequirement = .exactly(CAP23.minimumNumberOfQuestions)
		public var selectedQuestions: [SecurityQuestion]?

		public init(
			availableQuestions: NonEmpty<OrderedSet<SecurityQuestion>> = SecurityQuestionsFactorSource.defaultQuestions
		) {
			self.availableQuestions = availableQuestions
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case selectedQuestionsChanged([SecurityQuestion]?)
		case confirmedSelectedQuestions(NonEmpty<OrderedSet<SecurityQuestion>>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case choseQuestions(NonEmpty<OrderedSet<SecurityQuestion>>)
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case let .confirmedSelectedQuestions(questions):
			return .send(.delegate(.choseQuestions(questions)))

		case let .selectedQuestionsChanged(selected):
			state.selectedQuestions = selected
			return .none
		}
	}
}
