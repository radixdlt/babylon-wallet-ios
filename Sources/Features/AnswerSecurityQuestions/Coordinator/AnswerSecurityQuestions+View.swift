import FeaturePrelude

extension AnswerSecurityQuestions.State {
	var viewState: AnswerSecurityQuestions.ViewState {
		.init()
	}
}

// MARK: - AnswerSecurityQuestions.View
extension AnswerSecurityQuestions {
	public struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<AnswerSecurityQuestions>

		public init(store: StoreOf<AnswerSecurityQuestions>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			SwitchStore(
				store.scope(state: \.step)
			) {
				CaseLet(
					state: /AnswerSecurityQuestions.State.Step.flow,
					action: { AnswerSecurityQuestions.Action.child(.flow($0)) },
					then: { AnswerSecurityQuestionsFlow.View(store: $0) }
				)
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - AnswerSecurityQuestions_Preview
struct AnswerSecurityQuestions_Preview: PreviewProvider {
	static var previews: some View {
		AnswerSecurityQuestions.View(
			store: .init(
				initialState: .previewValue,
				reducer: AnswerSecurityQuestions()
			)
		)
	}
}

extension AnswerSecurityQuestions.State {
	public static let previewValue = Self()
}
#endif
