import AnswerSecurityQuestionsFeature
import FeaturePrelude

extension SimpleNewPhoneConfirmer.State {
	var viewState: SimpleNewPhoneConfirmer.ViewState {
		.init()
	}
}

// MARK: - SimpleNewPhoneConfirmer.View
extension SimpleNewPhoneConfirmer {
	public struct ViewState: Equatable {}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<SimpleNewPhoneConfirmer>

		public init(store: StoreOf<SimpleNewPhoneConfirmer>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			Color.white
				.sheet(
					store: store.scope(
						state: \.$answerSecurityQuestions,
						action: { .child(.answerSecurityQuestions($0)) }
					),
					content: { AnswerSecurityQuestions.View(store: $0) }
				)
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - SimpleNewPhoneConfirmer_Preview
struct SimpleNewPhoneConfirmer_Preview: PreviewProvider {
	static var previews: some View {
		SimpleNewPhoneConfirmer.View(
			store: .init(
				initialState: .previewValue,
				reducer: SimpleNewPhoneConfirmer()
			)
		)
	}
}

extension SimpleNewPhoneConfirmer.State {
	public static let previewValue = Self()
}
#endif
