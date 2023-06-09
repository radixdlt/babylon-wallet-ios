import ComposableArchitecture
import Cryptography
import DesignSystem
import FeaturePrelude
import Prelude
import SwiftUI

public extension AnswerSecurityQuestionsFreeform.State {
	var viewState: AnswerSecurityQuestionsFreeform.ViewState {
		.init(state: self)
	}
}

// MARK: - AnswerSecurityQuestionsFreeform.View
public extension AnswerSecurityQuestionsFreeform {
	struct ViewState: Equatable {
		public let question: String
		public let answer: String
		public let continueButtonState: ControlState
		public let buttonTitle: String
		init(state: AnswerSecurityQuestionsFreeform.State) {
			question = state.question.question.rawValue
			answer = state.answer.map(\.rawValue) ?? ""
			// FIXME: Strings
			buttonTitle = state.isLast ? "Submit" : "Next question"
			continueButtonState = state.answer == nil ? .disabled : .enabled
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
					ScrollView {
						VStack {
							LinearGradient(._1)
								.rotationEffect(.degrees(45))
								.mask {
									Image(systemName: "questionmark.app")
										.resizable()
										.padding(25)
								}
								.scaledToFit()
								.frame(idealHeight: 150)

							// FIXME: Strings
							Text("\(viewStore.question)?")
								.font(.app.sectionHeader)
								.fixedSize(horizontal: false, vertical: true)
								.padding()

							// FIXME: Strings
							TextField(
								"Answer",
								text: viewStore.binding(
									get: \.answer,
									send: { .answerChanged($0) }
								)
							)
							.textFieldStyle(.roundedBorder)
							.layoutPriority(1)
						}
					}
					.footer {
						Button(viewStore.buttonTitle) {
							viewStore.send(.submitAnswer)
						}
						.buttonStyle(.primaryRectangular)
						.controlState(viewStore.continueButtonState)
					}
					.padding()
					.navigationTitle("Answer Question")
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
		), isLast: true
	)
}
#endif
