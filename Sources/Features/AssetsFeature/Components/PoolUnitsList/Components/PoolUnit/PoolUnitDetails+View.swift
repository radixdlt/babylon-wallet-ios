import FeaturePrelude

extension PoolUnitDetails.State {
	var viewState: PoolUnitDetails.ViewState {
		// FIXME: Rewire
		.init(
			xViewState: .init(
				displayName: "temp",
				thumbnail: .xrd,
				amount: "2312.213223",
				symbol: "SYM"
			)
		)
	}
}

// MARK: - PoolUnitDetails.View
extension PoolUnitDetails {
	public struct ViewState: Equatable {
		let xViewState: DetailsContainerWithHeaderViewState
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<PoolUnitDetails>

		public init(store: StoreOf<PoolUnitDetails>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(
				store,
				observe: \.viewState,
				send: PoolUnitDetails.Action.view
			) { viewStore in
				DetailsContainerWithHeader(viewState: viewStore.xViewState) {
					EmptyView()
				} closeButtonAction: {
					viewStore.send(.closeButtonTapped)
				}
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
