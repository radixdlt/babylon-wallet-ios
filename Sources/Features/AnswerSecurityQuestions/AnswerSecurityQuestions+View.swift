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
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				Button("Done") {
					viewStore.send(.done)
				}
				.onAppear { viewStore.send(.done) }
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
