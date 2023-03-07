import FeaturePrelude

extension ManageFactorSources.State {
	var viewState: ManageFactorSources.ViewState {
		.init()
	}
}

// MARK: - ManageFactorSources.View
extension ManageFactorSources {
	public struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ManageFactorSources>

		public init(store: StoreOf<ManageFactorSources>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				// TODO: implement
				Text("Implement: ManageFactorSources")
					.background(Color.yellow)
					.foregroundColor(.red)
					.onAppear { viewStore.send(.appeared) }
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - ManageFactorSources_Preview
struct ManageFactorSources_Preview: PreviewProvider {
	static var previews: some View {
		ManageFactorSources.View(
			store: .init(
				initialState: .previewValue,
				reducer: ManageFactorSources()
			)
		)
	}
}

extension ManageFactorSources.State {
	public static let previewValue = Self()
}
#endif
