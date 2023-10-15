import ComposableArchitecture
import SwiftUI

// MARK: - AnswerSecurityQuestionsCoordinator.View
extension AnswerSecurityQuestionsCoordinator {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<AnswerSecurityQuestionsCoordinator>

		public init(store: StoreOf<AnswerSecurityQuestionsCoordinator>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			NavigationStackStore(
				store.scope(state: \.path, action: { .child(.path($0)) })
			) {
				path(for: self.store.scope(state: \.root, action: { .child(.root($0)) }))
					.toolbar {
						ToolbarItem(placement: .navigationBarLeading) {
							CloseButton {
								store.send(.view(.closeButtonTapped))
							}
						}
					}
					// This is required to disable the animation of internal components during transition
					.transaction { $0.animation = nil }
			} destination: {
				path(for: $0)
					.navigationBarBackButtonHidden()
					.toolbar {
						ToolbarItem(placement: .navigationBarLeading) {
							BackButton {
								store.send(.view(.backButtonTapped))
							}
						}
					}
			}
//			.navigationTransition(.slide, interactivity: .disabled)
		}

		func path(
			for store: StoreOf<AnswerSecurityQuestionsCoordinator.Path>
		) -> some SwiftUI.View {
			SwitchStore(store) { state in
				switch state {
				case .chooseQuestions:
					CaseLet(
						/AnswerSecurityQuestionsCoordinator.Path.State.chooseQuestions,
						action: AnswerSecurityQuestionsCoordinator.Path.Action.chooseQuestions,
						then: { ChooseQuestions.View(store: $0) }
					)

				case .answerQuestion:
					CaseLet(
						/AnswerSecurityQuestionsCoordinator.Path.State.answerQuestion,
						action: AnswerSecurityQuestionsCoordinator.Path.Action.answerQuestion,
						then: { AnswerSecurityQuestionFreeform.View(store: $0) }
					)
				}
			}
		}
	}
}

#if DEBUG
import ComposableArchitecture
import SwiftUI

// MARK: - AnswerSecurityQuestionsCoordinator_Preview
struct AnswerSecurityQuestionsCoordinator_Preview: PreviewProvider {
	static var previews: some View {
		AnswerSecurityQuestionsCoordinator.View(
			store: .init(
				initialState: .previewValue,
				reducer: AnswerSecurityQuestionsCoordinator.init
			)
		)
	}
}

extension AnswerSecurityQuestionsCoordinator.State {
	public static let previewValue = Self(purpose: .encrypt)
}
#endif
