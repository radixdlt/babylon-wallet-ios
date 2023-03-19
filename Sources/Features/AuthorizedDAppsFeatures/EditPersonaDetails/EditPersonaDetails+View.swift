import FeaturePrelude

extension EditPersonaDetails.State {
	var viewState: EditPersonaDetails.ViewState {
		.init()
	}
}

// MARK: - EditPersonaDetails.View
extension EditPersonaDetails {
	public struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<EditPersonaDetails>

		public init(store: StoreOf<EditPersonaDetails>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				// TODO: implement
				Text("Implement: EditPersonaDetails")
					.background(Color.yellow)
					.foregroundColor(.red)
					.onAppear { viewStore.send(.appeared) }
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - EditPersonaDetails_Preview
struct EditPersonaDetails_Preview: PreviewProvider {
	static var previews: some View {
		EditPersonaDetails.View(
			store: .init(
				initialState: .previewValue,
				reducer: EditPersonaDetails()
			)
		)
	}
}

extension EditPersonaDetails.State {
	public static let previewValue = Self()
}
#endif
