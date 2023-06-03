import FeaturePrelude

extension SimpleNewPhoneConfirmer.State {
	var viewState: SimpleNewPhoneConfirmer.ViewState {
		.init()
	}
}

// MARK: - SimpleNewPhoneConfirmer.View
extension SimpleNewPhoneConfirmer {
	public struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<SimpleNewPhoneConfirmer>

		public init(store: StoreOf<SimpleNewPhoneConfirmer>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				// TODO: implement
				Text("Implement: SimpleNewPhoneConfirmer")
					.background(Color.yellow)
					.foregroundColor(.red)
					.onAppear { viewStore.send(.appeared) }
			}
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
