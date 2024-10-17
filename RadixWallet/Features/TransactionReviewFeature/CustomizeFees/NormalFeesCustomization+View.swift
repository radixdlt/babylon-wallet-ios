import ComposableArchitecture
import SwiftUI

extension NormalFeesCustomization.State {
	var viewState: NormalFeesCustomization.ViewState {
		.init(
			feesViewState: .init(feeViewStates: fees.viewStates, totalFee: fees.total, isAdvancedMode: false)
		)
	}
}

extension NormalFeesCustomization {
	struct ViewState: Equatable, Sendable {
		let feesViewState: FeesView.ViewState
	}

	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<NormalFeesCustomization>

		var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState) { viewStore in
				FeesView(viewState: viewStore.feesViewState)
			}
		}
	}
}
