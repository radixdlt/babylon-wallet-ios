import ComposableArchitecture
import SwiftUI

extension NormalFeesCustomization.State {
	var feesViewState: FeesView.ViewState {
		FeesView.ViewState(
			feeViewStates: fees.viewStates,
			totalFee: fees.total,
			isAdvancedMode: false
		)
	}
}

// MARK: - NormalFeesCustomization.View
extension NormalFeesCustomization {
	@MainActor
	public struct View: SwiftUI.View {
		let store: StoreOf<NormalFeesCustomization>

		public var body: some SwiftUI.View {
			WithPerceptionTracking {
				FeesView(viewState: store.feesViewState)
			}
		}
	}
}
