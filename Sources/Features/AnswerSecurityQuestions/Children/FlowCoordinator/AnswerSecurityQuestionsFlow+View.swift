import ComposableArchitecture
import Cryptography
import DesignSystem
import FeaturePrelude
import Prelude
import SwiftUI

public extension AnswerSecurityQuestionsFlow {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<AnswerSecurityQuestionsFlow>

		public init(store: StoreOf<AnswerSecurityQuestionsFlow>) {
			self.store = store
		}

		// MARK: ViewState
		struct ViewState: Equatable {
			init(state: AnswerSecurityQuestionsFlow.State) {}
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
			for store: StoreOf<AnswerSecurityQuestionsFlow.Path>
		) -> some SwiftUI.View {
			SwitchStore(store) {
				CaseLet(
					state: /AnswerSecurityQuestionsFlow.Path.State.freeform,
					action: AnswerSecurityQuestionsFlow.Path.Action.freeform,
					then: { AnswerSecurityQuestionsFreeform.View(store: $0) }
				)
			}
		}
	}
}
