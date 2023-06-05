import ComposableArchitecture
import Cryptography
import DesignSystem
import FeaturePrelude
import Prelude
import SwiftUI

public extension AnswerSecurityQuestionsFreeform.State {
	var viewState: AnswerSecurityQuestionsFreeform.ViewState {
		.init(state: .init(question: self.question))
	}
}

// MARK: - AnswerSecurityQuestionsFreeform.View
public extension AnswerSecurityQuestionsFreeform {
	struct ViewState: Equatable {
		public let question: String
		public let answer: String
		public let submitButtonState: ControlState
		init(state: AnswerSecurityQuestionsFreeform.State) {
			question = state.question.question.rawValue
			answer = state.answer.map(\.rawValue) ?? ""
			submitButtonState = state.answer == nil ? .disabled : .enabled
		}
	}

	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<AnswerSecurityQuestionsFreeform>

		public init(store: StoreOf<AnswerSecurityQuestionsFreeform>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			ForceFullScreen {
				WithViewStore(
					store,
					observe: ViewState.init(state:),
					send: { .view($0) }
				) { viewStore in
					VStack {
						Text("Q: \(viewStore.question)")

						TextField(
							"Answer",
							text: viewStore.binding(
								get: \.answer,
								send: { .answerChanged($0) }
							)
						)
						.textFieldStyle(.roundedBorder)

						Button("Submit") {
							viewStore.send(.submitAnswer)
						}
						.buttonStyle(.primaryRectangular)
						.controlState(viewStore.submitButtonState)
					}
					.padding()
				}
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - AnswerSecurityQuestionsFreeform_Preview
struct AnswerSecurityQuestionsFreeform_Preview: PreviewProvider {
	static var previews: some View {
		AnswerSecurityQuestionsFreeform.View(
			store: .init(
				initialState: .previewValue,
				reducer: AnswerSecurityQuestionsFreeform()
			)
		)
	}
}

public extension AnswerSecurityQuestionsFreeform.State {
	static let previewValue = Self(
		question: .init(
			id: 0,
			question: "What was the make and model of your first car?"
		))
}
#endif
