import FeaturePrelude

extension PoolUnitDetails.State {
	var viewState: PoolUnitDetails.ViewState {
		.init()
	}
}

// MARK: - PoolUnitDetails.View
extension PoolUnitDetails {
	public struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<PoolUnitDetails>

		public init(store: StoreOf<PoolUnitDetails>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { _ in
				// TODO: implement
				Text("Implement: PoolUnitDetails")
					.background(Color.yellow)
					.foregroundColor(.red)
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - PoolUnitDetails_Preview
struct PoolUnitDetails_Preview: PreviewProvider {
	static var previews: some View {
		PoolUnitDetails.View(
			store: .init(
				initialState: .previewValue,
				reducer: PoolUnitDetails()
			)
		)
	}
}

extension PoolUnitDetails.State {
	public static let previewValue = Self()
}
#endif
