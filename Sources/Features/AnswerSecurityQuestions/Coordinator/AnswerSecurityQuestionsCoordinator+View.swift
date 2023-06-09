import FeaturePrelude

extension AnswerSecurityQuestionsCoordinator.State {
	var viewState: AnswerSecurityQuestionsCoordinator.ViewState {
		.init()
	}
}

// MARK: - AnswerSecurityQuestionsCoordinator.View
extension AnswerSecurityQuestionsCoordinator {
	public struct ViewState: Equatable {
		// TODO: declare some properties
	}

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
				IfLetStore(
					store.scope(state: \.root, action: { .child(.root($0)) })
				) {
					path(for: $0)
					#if os(iOS)
						.toolbar {
							ToolbarItem(placement: .navigationBarLeading) {
								CloseButton {
									ViewStore(store.stateless).send(.view(.closeButtonTapped))
								}
							}
						}
					#endif
				}
				// This is required to disable the animation of internal components during transition
				.transaction { $0.animation = nil }
			} destination: {
				path(for: $0)
				#if os(iOS)
					.navigationBarBackButtonHidden()
					.toolbar {
						ToolbarItem(placement: .navigationBarLeading) {
							BackButton {
								ViewStore(store.stateless).send(.view(.backButtonTapped))
							}
						}
					}
				#endif
			}
			#if os(iOS)
			.navigationTransition(.slide, interactivity: .disabled)
			#endif
		}

		func path(
			for store: StoreOf<AnswerSecurityQuestionsCoordinator.Path>
		) -> some SwiftUI.View {
			SwitchStore(store) {
				CaseLet(
					state: /AnswerSecurityQuestionsCoordinator.Path.State.chooseQuestions,
					action: AnswerSecurityQuestionsCoordinator.Path.Action.chooseQuestions,
					then: { ChooseQuestions.View(store: $0) }
				)
				CaseLet(
					state: /AnswerSecurityQuestionsCoordinator.Path.State.answerQuestion,
					action: AnswerSecurityQuestionsCoordinator.Path.Action.answerQuestion,
					then: { AnswerSecurityQuestionsFreeform.View(store: $0) }
				)
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - AnswerSecurityQuestionsCoordinator_Preview
struct AnswerSecurityQuestionsCoordinator_Preview: PreviewProvider {
	static var previews: some View {
		AnswerSecurityQuestionsCoordinator.View(
			store: .init(
				initialState: .previewValue,
				reducer: AnswerSecurityQuestionsCoordinator()
			)
		)
	}
}

extension AnswerSecurityQuestionsCoordinator.State {
	public static let previewValue = Self(purpose: .encrypt)
}
#endif
