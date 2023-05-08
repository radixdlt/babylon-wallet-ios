import FeaturePrelude

extension CreateAuthKey.State {
	var viewState: CreateAuthKey.ViewState {
		.init()
	}
}

// MARK: - CreateAuthKey.View
extension CreateAuthKey {
	public struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<CreateAuthKey>

		public init(store: StoreOf<CreateAuthKey>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				// TODO: implement
				Text("Implement: CreateAuthKey")
					.background(Color.yellow)
					.foregroundColor(.red)
					.onAppear { viewStore.send(.appeared) }
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - CreateAuthKey_Preview
struct CreateAuthKey_Preview: PreviewProvider {
	static var previews: some View {
		CreateAuthKey.View(
			store: .init(
				initialState: .previewValue,
				reducer: CreateAuthKey()
			)
		)
	}
}

extension CreateAuthKey.State {
	public static let previewValue = Self()
}
#endif
