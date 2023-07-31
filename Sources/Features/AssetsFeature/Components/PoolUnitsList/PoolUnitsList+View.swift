import FeaturePrelude

extension PoolUnitsList.State {
	var viewState: PoolUnitsList.ViewState {
		.init()
	}
}

// MARK: - PoolUnitsList.View
extension PoolUnitsList {
	public struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<PoolUnitsList>

		public init(store: StoreOf<PoolUnitsList>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				// TODO: implement
				Text("Implement: PoolUnitsList")
					.background(Color.yellow)
					.foregroundColor(.red)
					.onAppear { viewStore.send(.appeared) }
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - PoolUnitsList_Preview
struct PoolUnitsList_Preview: PreviewProvider {
	static var previews: some View {
		PoolUnitsList.View(
			store: .init(
				initialState: .previewValue,
				reducer: PoolUnitsList()
			)
		)
	}
}

extension PoolUnitsList.State {
	public static let previewValue = Self()
}
#endif
