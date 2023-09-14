import ComposableArchitecture
import Cryptography
import DesignSystem
import FeaturePrelude
import Prelude
import SwiftUI

public extension AnswerSecurityQuestionFreeform.State {
	var viewState: AnswerSecurityQuestionFreeform.ViewState {
		.init(state: self)
	}
}

// MARK: - AnswerSecurityQuestionFreeform.View
public extension AnswerSecurityQuestionFreeform {
	struct ViewState: Equatable {
		public let question: String
		public let answer: String
		public let buttonTitle: String
		public let keyDerivationScheme: SecurityQuestionsFactorSource.KeyDerivationScheme
		init(state: AnswerSecurityQuestionFreeform.State) {
			question = state.question.question.rawValue
			answer = state.answer.map(\.rawValue) ?? ""
			// FIXME: Strings
			buttonTitle = state.isLast ? "Submit" : "Next question"
			keyDerivationScheme = state.keyDerivationScheme
		}

		var validAnswer: SecurityQuestionAnswerAsEntropy? {
			try? keyDerivationScheme.validateConversionToEntropyOf(answer: answer)
		}
	}

	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<AnswerSecurityQuestionFreeform>

		public init(store: StoreOf<AnswerSecurityQuestionFreeform>) {
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
						WithControlRequirements(
							viewStore.validAnswer,
							forAction: { viewStore.send(.submitAnswer($0)) }
						) { action in
							Button(viewStore.buttonTitle, action: action)
								.buttonStyle(.primaryRectangular)
						}
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
		AnswerSecurityQuestionFreeform.View(
			store: .init(
				initialState: .previewValue,
				reducer: AnswerSecurityQuestionFreeform.init
			)
		)
	}
}

public extension AnswerSecurityQuestionFreeform.State {
	static let previewValue = Self(
		keyDerivationScheme: .default,
		question: .init(
			id: 0,
			question: "What was the make and model of your first car?"
		), isLast: true
	)
}
#endif
