import FeaturePrelude

extension PoolUnitToken.State {
	var viewState: PoolUnitToken.ViewState {
		.init()
	}
}

// MARK: - PoolUnitToken.View
extension PoolUnitToken {
	public struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<PoolUnitToken>

		public init(store: StoreOf<PoolUnitToken>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				// TODO: implement
				Text("Implement: PoolUnitToken")
					.background(Color.yellow)
					.foregroundColor(.red)
					.onAppear { viewStore.send(.appeared) }
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - PoolUnitToken_Preview
struct PoolUnitToken_Preview: PreviewProvider {
	static var previews: some View {
		PoolUnitToken.View(
			store: .init(
				initialState: .previewValue,
				reducer: PoolUnitToken()
			)
		)
	}
}

extension PoolUnitToken.State {
	public static let previewValue = Self()
}
#endif
